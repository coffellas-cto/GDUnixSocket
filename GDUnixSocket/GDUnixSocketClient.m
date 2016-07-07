//
//  GDUnixSocketClient.m
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

#import "GDUnixSocketClient.h"
#import "GDUnixSocket_Private.h"

#include <stdio.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <string.h>

@implementation GDUnixSocketClient

#pragma mark - Public Methods

- (BOOL)connectWithAutoRead:(BOOL)autoRead error:(NSError **)error {
    BOOL retVal = NO;
    NSError *retError = nil;
    dispatch_fd_t socket_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    [self setFd:socket_fd];
    if (socket_fd == kGDBadSocketFD) {
        retError = [NSError gduds_errorForCode:GDUnixSocketErrorBadSocket info:[self lastErrorInfo]];
    } else {
        const char *socket_path = [self.socketPath cStringUsingEncoding:NSUTF8StringEncoding];
        struct sockaddr_un address = {};
        address.sun_family = AF_UNIX;
        strncpy(address.sun_path, socket_path, sizeof(address.sun_path) - 1);
        if (0 != strcmp(address.sun_path, socket_path)) {
            [self close];
            retError = [NSError gduds_errorForCode:GDUnixSocketErrorListen info:@"The socket path is inconsistent"];
        } else {
            if (0 != connect(socket_fd, (struct sockaddr *)&address, sizeof(struct sockaddr_un))) {
                retError = [NSError gduds_errorForCode:GDUnixSocketErrorConnect info:[self lastErrorInfo]];
                [self close];
            } else {
                retVal = YES;
            }
        }
    }
    
    if (error) {
        *error = retError;
    }
    
    if (retVal) {
        self.state = GDUnixSocketStateConnected;
        if (autoRead) {
            [self readLoop];
        }
    }
    
    return retVal;
}

- (void)connectWithAutoRead:(BOOL)autoRead completion:(void(^)(NSError *error))completion {
    // TODO: Implement with non-blocking connect & select/poll.
    NSAssert(NO, @"Sorry, this one is not implemented");
}

#pragma mark - Overrides

- (NSData *)readWithError:(NSError **)error {
    NSError *readError = nil;
    NSData *data = [super readWithError:&readError];
    if (readError) {
        if ([self.delegate respondsToSelector:@selector(unixSocketClient:didFailToReadWithError:)]) {
            [self.delegate unixSocketClient:self didFailToReadWithError:readError];
        }
    } else if (data) {
        if ([self.delegate respondsToSelector:@selector(unixSocketClient:didReceiveData:)]) {
            [self.delegate unixSocketClient:self didReceiveData:data];
        }
    }
    
    if (error) {
        *error = readError;
    }
    
    return data;
}

#pragma mark - Private Methods

- (void)readLoop {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *readData = nil;
        do {
            readData = [self readWithError:nil];
        } while (readData);
        
        [self close];
    });
}

@end
