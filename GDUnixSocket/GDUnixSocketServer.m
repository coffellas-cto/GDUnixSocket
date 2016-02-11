//
//  GDUnixSocketServer.m
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDUnixSocketServer.h"
#import "GDUnixSocketConnection_Private.h"

#include <stdio.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <string.h>

#include <sys/stat.h>

const int kGDUnixSocketServerMaxConnectionsDefault = 5;

@interface GDUnixSocketServer ()

@property (nonatomic, readonly, strong) NSLock *closeLock;

@end

@implementation GDUnixSocketServer

#pragma mark - Public Methods

- (NSError *)listen {
    return [self listenWithMaxConnections:0];
}

- (NSError *)listenWithMaxConnections:(int)maxConnections {
    dispatch_fd_t socket_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    [self setFd:socket_fd];
    if (socket_fd == kGDBadSocketFD) {
        return [NSError gduds_errorForCode:GDUnixSocketErrorBadSocket info:[self lastErrorInfo]];
    }
    
    const char *socket_path = [self.socketPath cStringUsingEncoding:NSUTF8StringEncoding];
    
    struct sockaddr_un address = {};
    address.sun_family = AF_UNIX;
    strncpy(address.sun_path, socket_path, sizeof(address.sun_path) - 1);
    if (0 != strcmp(address.sun_path, socket_path)) {
        [self close];
        return [NSError gduds_errorForCode:GDUnixSocketErrorListen info:@"The socket path is inconsistent"];
    }
    
    socket_path = address.sun_path;
    
    [self unlinkSocket:socket_path];
    
    if (0 != bind(socket_fd, (struct sockaddr *)&address, sizeof(struct sockaddr_un))) {
        [self close];
        return [NSError gduds_errorForCode:GDUnixSocketErrorBind info:[self lastErrorInfo]];
    }
    
    if (0 != listen(socket_fd, maxConnections ?: kGDUnixSocketServerMaxConnectionsDefault)) {
        [self close];
        return [NSError gduds_errorForCode:GDUnixSocketErrorListen info:[self lastErrorInfo]];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self mainLoop];
    });

    return nil;
}

#pragma mark - Overrides

- (NSError *)close {
    [self.closeLock lock];
    NSError *retVal = [self unlinkSocket];
    if (!retVal) {
        retVal = [super close];
    }
    if ([self.delegate respondsToSelector:@selector(unixSocketServerDidClose:error:)]) {
        [self.delegate unixSocketServerDidClose:self error:retVal];
    }
    [self.closeLock unlock];
    
    return retVal;
}

#pragma mark - Private Methods

- (void)readOnConnection:(dispatch_fd_t)connection_fd {
    NSError *error;
    do {
        NSData *data = [self readFromSocket:connection_fd error:&error];
        if (!error) {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%s %@", __PRETTY_FUNCTION__, dataString);
            if ([dataString rangeOfString:@"hello" options:NSCaseInsensitiveSearch].length) {
                [self write:[@"Well, well, well..." dataUsingEncoding:NSUTF8StringEncoding] toSocket:connection_fd error:nil];
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
                if ([self.delegate respondsToSelector:@selector(unixSocketServerDidFailToAcceptConnection:error:)]) {
                    NSError *error = [NSError gduds_errorForCode:GDUnixSocketErrorAccept info:[self lastErrorInfo]];
                    [self.delegate unixSocketServerDidFailToAcceptConnection:self error:error];
                }
                
                [self close];
            }
            
            [self.closeLock unlock];
            break;
        } else {
            GDUnixSocketConnection *newConnection = [[GDUnixSocketConnection alloc] initWithSocketPath:@"(dummy)"];
            [newConnection setFd:connection_fd];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self readOnConnection:connection_fd];
            });
            // TODO: Store connections and close them when needed.
            if ([self.delegate respondsToSelector:@selector(unixSocketServer:didAcceptConnection:)]) {
                [self.delegate unixSocketServer:self didAcceptConnection:newConnection];
            } else {
                [newConnection close];
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

#pragma mark - Life Cycle

- (instancetype)initWithSocketPath:(NSString *)socketPath
{
    self = [super initWithSocketPath:socketPath];
    if (self) {
        _closeLock = [NSLock new];
    }
    return self;
}

@end
