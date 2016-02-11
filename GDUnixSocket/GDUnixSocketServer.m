//
//  GDUnixSocketServer.m
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDUnixSocketServer.h"
#import "GDUnixSocket_Private.h"

#include <stdio.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <string.h>

#include <sys/stat.h>

const int kGDUnixSocketServerMaxConnectionsDefault = 5;

@interface GDUnixSocketServer ()

@property (nonatomic, readonly, strong) NSLock *closeLock;
@property (nonatomic, readonly, strong) NSMutableDictionary *connectedClients;

@end

@implementation GDUnixSocketServer

#pragma mark - Public Methods

- (BOOL)listenWithError:(NSError **)error {
    return [self listenWithMaxConnections:0 error:error];
}

- (BOOL)listenWithMaxConnections:(int)maxConnections error:(NSError **)error {
    BOOL(^failureDeferBlock)(NSError *) = ^BOOL(NSError *retError) {
        if (error) {
            *error = retError;
        }
        
        return NO;
    };
    
    dispatch_fd_t socket_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    [self setFd:socket_fd];
    if (socket_fd == kGDBadSocketFD) {
        return failureDeferBlock([NSError gduds_errorForCode:GDUnixSocketErrorBadSocket info:[self lastErrorInfo]]);
    }
    
    const char *socket_path = [self.socketPath cStringUsingEncoding:NSUTF8StringEncoding];
    
    struct sockaddr_un address = {};
    address.sun_family = AF_UNIX;
    strncpy(address.sun_path, socket_path, sizeof(address.sun_path) - 1);
    if (0 != strcmp(address.sun_path, socket_path)) {
        [self close];
        return failureDeferBlock([NSError gduds_errorForCode:GDUnixSocketErrorListen info:@"The socket path is inconsistent"]);
    }
    
    socket_path = address.sun_path;
    
    [self unlinkSocket:socket_path];
    
    if (0 != bind(socket_fd, (struct sockaddr *)&address, sizeof(struct sockaddr_un))) {
        [self close];
        return failureDeferBlock([NSError gduds_errorForCode:GDUnixSocketErrorBind info:[self lastErrorInfo]]);
    }
    
    if (0 != listen(socket_fd, maxConnections ?: kGDUnixSocketServerMaxConnectionsDefault)) {
        [self close];
        return failureDeferBlock([NSError gduds_errorForCode:GDUnixSocketErrorListen info:[self lastErrorInfo]]);
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self mainLoop];
    });
    
    return nil;
}

- (ssize_t)sendData:(NSData *)data toClientWithID:(NSString *)clientID error:(NSError **)error {
    @synchronized(self) {
        GDUnixSocket *client = self.connectedClients[clientID];
        if (!client) {
            if (error) {
                *error = [NSError gduds_errorForCode:GDUnixSocketErrorUnknownClient info:[NSString stringWithFormat:@"Client ID: %@", clientID]];
            }
            
            return -1;
        }
        
        return [client writeData:data error:error];
    }
}

- (void)sendData:(NSData *)data toClientWithID:(NSString *)clientID completion:(void(^)(NSError *error, ssize_t size))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        ssize_t size = [self sendData:data toClientWithID:clientID error:&error];
        if (completion) {
            completion(error, size);
        }
    });
}

#pragma mark - Overrides

- (BOOL)closeWithError:(NSError **)error {
    BOOL retVal = NO;
    // First, close all active clients.
    [self removeAllClients];
    
    // Then close the listening socket.
    [self.closeLock lock];
    NSError *retError = [self unlinkSocket];
    if (!retError) {
        retVal = [super closeWithError:&retError];
    }
    
    if ([self.delegate respondsToSelector:@selector(unixSocketServerDidClose:error:)]) {
        [self.delegate unixSocketServerDidClose:self error:retError];
    }
    
    [self.closeLock unlock];
    
    if (retError && error) {
        *error = retError;
    }
    
    return retVal;
}

#pragma mark - Private Methods

- (void)readOnConnection:(GDUnixSocket *)clientConnection {
    NSError *error;
    do {
        if (![self clientExists:clientConnection]) {
            break;
        }
        
        NSData *data = [clientConnection readWithError:&error];
        if (error) {
            if ([self clientExists:clientConnection]) {
                if ([self.delegate respondsToSelector:@selector(unixSocketServer:didFailToReadForClientID:error:)]) {
                    [self.delegate unixSocketServer:self didFailToReadForClientID:clientConnection.uniqueID error:error];
                }
                
                [self removeAndCloseClient:clientConnection];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(unixSocketServer:didReceiveData:fromClientWithID:)]) {
                [self.delegate unixSocketServer:self didReceiveData:data fromClientWithID:clientConnection.uniqueID];
            }
        }
    } while (!error);
}

- (void)mainLoop {
    while (true) {
        dispatch_fd_t socket_fd = [self fd];
        if (socket_fd == kGDBadSocketFD) {
            break;
        }
        
        struct sockaddr_un connection_addr = {};
        socklen_t connection_addr_len;
        dispatch_fd_t connection_fd = accept(socket_fd, (struct sockaddr *)&connection_addr, &connection_addr_len);
        if (connection_fd == kGDBadSocketFD) {
            [self.closeLock lock];
            if ([self fd] != kGDBadSocketFD) {
                // If accept failed, that means some error happened. Close listening socket.
                if ([self.delegate respondsToSelector:@selector(unixSocketServerDidFailToAcceptConnection:error:)]) {
                    NSError *error = [NSError gduds_errorForCode:GDUnixSocketErrorAccept info:[self lastErrorInfo]];
                    [self.delegate unixSocketServerDidFailToAcceptConnection:self error:error];
                }
                
                [self.closeLock unlock];
                [self close];
            } else {
                [self.closeLock unlock];
            }
            break;
        } else {
            GDUnixSocket *newConnection = [[GDUnixSocket alloc] initWithSocketPath:@"(dummy)"];
            [newConnection setFd:connection_fd];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self readOnConnection:newConnection];
            });
            
            [self addClient:newConnection];
            
            if ([self.delegate respondsToSelector:@selector(unixSocketServer:didAcceptClientWithID:)]) {
                [self.delegate unixSocketServer:self didAcceptClientWithID:newConnection.uniqueID];
            }
        }
    }
}

- (NSError *)unlinkSocket {
    return [self unlinkSocket:[self.socketPath cStringUsingEncoding:NSUTF8StringEncoding]];
}

- (NSError *)unlinkSocket:(const char *)socketPath {
    int status;
    struct stat st;
    status = stat(socketPath, &st);
    if (status == 0) {
        // A file already exists. Check if this file is a socket node. If yes: unlink it.
        if ((st.st_mode & S_IFMT) == S_IFSOCK) {
            if (0 != unlink(socketPath)) {
                return [NSError gduds_errorForCode:GDUnixSocketErrorUnlink info:[self lastErrorInfo]];
            }
        }
    }
    
    return nil;
}

#pragma mark - Clients Related

- (void)addClient:(GDUnixSocket *)client {
    @synchronized(self) {
        self.connectedClients[client.uniqueID] = client;
    }
}

- (BOOL)clientExists:(GDUnixSocket *)client {
    @synchronized(self) {
        return self.connectedClients[client.uniqueID];
    }
}

- (NSError *)removeAndCloseClient:(GDUnixSocket *)client {
    if ([self clientExists:client]) {
        @synchronized(self) {
            [self.connectedClients removeObjectForKey:client.uniqueID];
            NSError *error = nil;
            [client closeWithError:&error];
            return error;
        }
    }
    
    return nil;
}

- (void)removeAllClients {
    @synchronized(self) {
        for (GDUnixSocket *client in self.connectedClients.allValues) {
            [client close];
        }
        
        [self.connectedClients removeAllObjects];
    }
}

#pragma mark - Life Cycle

- (instancetype)initWithSocketPath:(NSString *)socketPath  andFragmentSize:(size_t)fragmentSize {
    self = [super initWithSocketPath:socketPath andFragmentSize:fragmentSize];
    if (self) {
        _closeLock = [NSLock new];
        _connectedClients = [NSMutableDictionary new];
    }
    return self;
}

@end
