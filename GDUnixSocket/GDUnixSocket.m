//
//  GDUnixSocket.m
//
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

/*
 The MIT License (MIT)
 
 Copyright (c) 2016 A. Gordiyenko
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

#import "GDUnixSocket_Private.h"

#import <sys/un.h>
#import <sys/socket.h>

#pragma mark - Constants

const int kGDBadSocketFD = -1;
NSString * const kGDUnixSocketErrDomain = @"com.coffellas.GDUnixSocket";
NSString * const kGDDummySocketPath = @"(dummy)";

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
        case GDUnixSocketErrorUnknownClient:
            localizedDescription = @"Unknown client. It is either disconnected or never existed";
            break;
            
        default:
            localizedDescription = @"Unknown Error";
            break;
    }
    
    if (infoString.length) {
        localizedDescription = [NSString stringWithFormat:@"%@. %@", localizedDescription, infoString];
    }
    
    GDUnixSocketLog(@"Error: %@", localizedDescription);
    
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
            _uniqueID = [NSUUID UUID].UUIDString;
        }
    }
    
    return _uniqueID;
}

#pragma mark - Public Methods

- (ssize_t)writeData:(NSData *)data error:(NSError **)error {
    return [self write:data toSocket:[self fd] error:error];
}

- (void)writeData:(NSData *)data completion:(void(^)(NSError *error, ssize_t size))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        ssize_t size = [self writeData:data error:&error];
        if (completion) {
            completion(error, size);
        }
    });
}

- (NSData *)readWithError:(NSError **)error {
    return [self readFromSocket:[self fd] error:error];
}

- (void)readWithCompletion:(void(^)(NSError *error, NSData *data))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSData *data = [self readWithError:&error];
        if (completion) {
            completion(error, data);
        }
    });
}

- (BOOL)close {
    return [self closeWithError:nil];
}

- (BOOL)closeWithError:(NSError **)error {
    if (self.state == GDUnixSocketStateDisconnected) {
        return YES;
    }
    
    BOOL retVal = NO;
    NSError *retError = [self checkForBadSocket];
    if (retError) {
        NSString *tmpDescription = retError.localizedDescription;
        retError = [NSError gduds_errorForCode:GDUnixSocketErrorClose info:tmpDescription];
    } else {
        retVal = close([self fd]) != -1;
        if (!retVal) {
            retError = [NSError gduds_errorForCode:GDUnixSocketErrorClose info:[self lastErrorInfo]];
        } else {
            GDUnixSocketLog(@"closed socket [%d]", [self fd]);
        }
        
        [self setFd:kGDBadSocketFD];
    }
    
    if (error) {
        *error = retError;
    }
    
    if (retVal) {
        self.state = GDUnixSocketStateDisconnected;
    }
    
    return retVal;
}

#pragma mark - Private Methods

- (NSData *)readFromSocket:(dispatch_fd_t)socket_fd error:(NSError **)error {
    NSData *retVal = nil;
    NSError *retError = nil;
    size_t buffer_size = self.fragmentSize;
    uint8_t *buffer = calloc(buffer_size, sizeof(uint8_t));
    ssize_t bytes_read = read(socket_fd, buffer, buffer_size);
    if (bytes_read == -1) {
        retError = [NSError gduds_errorForCode:GDUnixSocketErrorSocketRead info:[self lastErrorInfoForSocket:socket_fd]];
    } else {
        GDUnixSocketLog(@"read %zd bytes from socket [%d]: %s", bytes_read, socket_fd, buffer);
    }
    
    if (bytes_read > 0) {
        retVal = [NSData dataWithBytesNoCopy:buffer length:bytes_read freeWhenDone:YES];
    } else {
        free(buffer);
    }
    
    if (error) {
        *error = retError;
    }
    
    return retVal;
}

- (ssize_t)write:(NSData *)data toSocket:(dispatch_fd_t)socket_fd error:(NSError **)error {
    if (error) {
        *error = nil;
    }
    
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
    
    GDUnixSocketLog(@"written %zd bytes on socket [%d]: %s", written, socket_fd, buffer);
    return written;
}

- (NSString *)lastErrorInfo {
    return [self lastErrorInfoForSocket:[self fd]];
}

- (NSString *)lastErrorInfoForSocket:(dispatch_fd_t)socket_fd {
    int error;
    // TODO: Switch to `getsockopt`. The code commented out below is not accurate.
//    socklen_t len = sizeof(error);
//    if (-1 == getsockopt(socket_fd, SOL_SOCKET, SO_ERROR, &error, &len)) {
        error = errno;
//    }
    return [NSString stringWithFormat:@"fd: %d. errno: %d. %s", socket_fd, error, strerror(error)];
}

- (NSError *)checkForBadSocket {
    return [self checkForBadSocket:[self fd]];
}

- (NSError *)checkForBadSocket:(dispatch_fd_t)socket_fd {
    if (socket_fd == kGDBadSocketFD) {
        return [NSError gduds_errorForCode:GDUnixSocketErrorBadSocket];
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
    return [self initWithSocketPath:socketPath andFragmentSize:256];
}

- (instancetype)initWithSocketPath:(NSString *)socketPath andFragmentSize:(size_t)fragmentSize {
    NSParameterAssert(socketPath);
    
    self = [super init];
    if (self) {
        _fd = kGDBadSocketFD;
        
        if (!socketPath.length) {
            return nil;
        }
        
        if (![socketPath isEqualToString:kGDDummySocketPath]) {
            NSString *standardizedPath = [socketPath stringByStandardizingPath]; // Returns self if an error occurs.
            if (![standardizedPath isEqualToString:socketPath]) {
                return nil;
            }
            
            if (![standardizedPath rangeOfString:@"/"].length) {
                return nil;
            }
        }
        
        struct sockaddr_un address;
        size_t allowed_size = sizeof(address.sun_path) - 1;
        if (strlen([socketPath cStringUsingEncoding:NSUTF8StringEncoding]) > allowed_size) {
            return nil;
        }

        _socketPath = [socketPath copy];
        _fragmentSize = fragmentSize;
    }
    
    return self;
}

- (instancetype)init {
    return [self initWithSocketPath:nil];
}

- (void)dealloc {
    if (_fd != kGDBadSocketFD) {
        [self close];
    }
}

@end
