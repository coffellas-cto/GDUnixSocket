//
//  GDUnixSocket.m
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDUnixSocket.h"

#import <sys/un.h>

#pragma mark - Constants

const int kGDBadSocketFD = -1;
NSString * const kGDUnixSocketErrDomain = @"com.coffellas.GDUnixSocket";

#pragma mark - NSError

@implementation NSError (GDUnixSocket)

+ (NSError *)gduds_errorForCode:(GDUnixSocketError)code {
    return [self gduds_errorForCode:code info:nil];
}

+ (NSError *)gduds_errorForCode:(GDUnixSocketError)code info:(NSString *)infoString {
    NSString *localizedDescription;
    switch (code) {
        case GDUnixSocketErrorBadSocket:
            localizedDescription = @"Bad socket";
            break;
        case GDUnixSocketErrorBind:
            localizedDescription = @"Failed to bind socket";
            break;
        case GDUnixSocketErrorListen:
            localizedDescription = @"Failed to listen on socket";
            break;
        case GDUnixSocketErrorAccept:
            localizedDescription = @"Failed to accept connection, closing socket";
            break;
        case GDUnixSocketErrorUnlink:
            localizedDescription = @"Failed to unlink socket";
            break;
        case GDUnixSocketErrorConnect:
            localizedDescription = @"Failed to connect to socket";
            break;
        case GDUnixSocketErrorSocketWrite:
            localizedDescription = @"Failed to write to socket";
            break;
        case GDUnixSocketErrorSocketRead:
            localizedDescription = @"Failed to read from socket";
            break;
        case GDUnixSocketErrorClose:
            localizedDescription = @"Failed to close socket";
            break;
            
        default:
            localizedDescription = @"Unknown Error";
            break;
    }
    
    if (infoString.length) {
        localizedDescription = [NSString stringWithFormat:@"%@. %@", localizedDescription, infoString];
    }
    
    NSLog(@"Error: %@", localizedDescription);
    
    return [NSError errorWithDomain:kGDUnixSocketErrDomain code:code userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
}

@end

#pragma mark - GDUnixSocket

@interface GDUnixSocket () {
    dispatch_fd_t _fd;
}

@end


@implementation GDUnixSocket

@synthesize uniqueID = _uniqueID;

#pragma mark - Accessors

- (NSString *)uniqueID {
    @synchronized(self) {
        if (!_uniqueID) {
            _uniqueID = [[[NSString stringWithFormat:@"%d", [self fd]] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
        }
    }
    
    return _uniqueID;
}

#pragma mark - Public Methods

- (ssize_t)write:(NSData *)data error:(NSError **)error {
    return [self write:data toSocket:[self fd] error:error];
}

- (NSData *)readWithError:(NSError **)error {
    return [self readFromSocket:[self fd] error:error];
}

- (NSError *)close {
    NSError *socketError = [self checkForBadSocket];
    if (socketError) {
        return socketError;
    }
    
    if (-1 == close([self fd])) {
        return [NSError gduds_errorForCode:GDUnixSocketErrorClose info:[self lastErrorInfo]];
    }
    
    [self setFd:kGDBadSocketFD];
    return nil;
}

#pragma mark - Private Methods

- (NSData *)readFromSocket:(dispatch_fd_t)socket_fd error:(NSError **)error {
    char buffer[256] = {};
    ssize_t bytes_read = read(socket_fd, buffer, 256);
    if (bytes_read == -1) {
        if (error) {
            *error = [NSError gduds_errorForCode:GDUnixSocketErrorSocketRead info:[self lastErrorInfoForSocket:socket_fd]];
        }
        return nil;
    }
    
    NSLog(@"read %zd bytes from socket [%d]: %s", bytes_read, socket_fd, buffer);
    return [NSData dataWithBytes:buffer length:bytes_read];
}

- (ssize_t)write:(NSData *)data toSocket:(dispatch_fd_t)socket_fd error:(NSError **)error {
    if (!data || !data.length) {
        return 0;
    }
    
    NSError *socketError = [self checkForBadSocket:socket_fd];
    if (socketError) {
        if (error) {
            *error = socketError;
        }
        
        return -1;
    }
    
    const void *buffer = data.bytes;
    size_t length = data.length;
    
    ssize_t written = write(socket_fd, buffer, length);
    if (-1 == written && error) {
        *error = [NSError gduds_errorForCode:GDUnixSocketErrorSocketWrite info:[self lastErrorInfoForSocket:socket_fd]];
    }
    
    NSLog(@"written %zd bytes on socket [%d]: %s", written, socket_fd, buffer);
    return written;
}

- (NSString *)lastErrorInfo {
    return [self lastErrorInfoForSocket:[self fd]];
}

- (NSString *)lastErrorInfoForSocket:(dispatch_fd_t)socket_fd {
    int last_error = errno;
    return [NSString stringWithFormat:@"fd: %d. errno: %d. %s", socket_fd, last_error, strerror(last_error)];
}

- (NSError *)checkForBadSocket {
    return [self checkForBadSocket:[self fd]];
}

- (NSError *)checkForBadSocket:(dispatch_fd_t)socket_fd {
    if (socket_fd == kGDBadSocketFD) {
        [NSError gduds_errorForCode:GDUnixSocketErrorBadSocket];
    }
    
    return nil;
}

- (dispatch_fd_t)fd {
    @synchronized(self) {
        return _fd;
    }
}

- (void)setFd:(dispatch_fd_t)fd {
    @synchronized(self) {
        _fd = fd;
    }
}

- (NSString *)debugDescription {
    return self.uniqueID;
}

- (NSString *)description {
    return self.uniqueID;
}

#pragma mark - Life Cycle

- (instancetype)initWithSocketPath:(NSString *)socketPath {
    NSParameterAssert(socketPath);
    
    if (!socketPath.length) {
        return nil;
    }
    
    struct sockaddr_un address;
    size_t allowed_size = sizeof(address.sun_path) - 1;
    if (strlen([socketPath cStringUsingEncoding:NSUTF8StringEncoding]) > allowed_size) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _socketPath = [socketPath copy];
        _fd = kGDBadSocketFD;
    }
    
    return self;
}

- (instancetype)init {
    return [self initWithSocketPath:nil];
}

@end
