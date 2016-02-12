//
//  GDUnixSocketClient.m
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

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
    
    if (retError && error) {
        *error = retError;
    }
    
    if (retVal) {
        self.state = GDUnixSocketStateConnected;
        if (autoRead) {
            [self readNext];
        }
    }
    
    return retVal;
}

- (void)connectWithAutoRead:(BOOL)autoRead completion:(void(^)(NSError *error))completion {
    // TODO: Implement with non-blocking connect & select/poll.
}

#pragma mark - Overrides

- (NSData *)readWithError:(NSError **)error {
    NSError *readError = nil;
    NSData *data = [super readWithError:&readError];
    if (readError) {
        if ([self.delegate respondsToSelector:@selector(unixSocketClient:didFailToReadWithError:)]) {
            [self.delegate unixSocketClient:self didFailToReadWithError:readError];
        }
        
        if (error) {
            *error = readError;
        }
    } else if (data) {
        if ([self.delegate respondsToSelector:@selector(unixSocketClient:didReceiveData:)]) {
            [self.delegate unixSocketClient:self didReceiveData:data];
        }
    }
    
    return data;
}

#pragma mark - Private Methods

- (void)readNext {
    [self readWithCompletion:^(NSError *error, NSData *data) {
        if (data) {
            [self readNext];
        } else {
            [self close];
        }
    }];
}

@end
