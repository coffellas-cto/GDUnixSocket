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

- (BOOL)connectWithError:(NSError **)error {
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
                [self close];
                retError = [NSError gduds_errorForCode:GDUnixSocketErrorConnect info:[self lastErrorInfo]];
            } else {
                retVal = YES;
            }
        }
    }
    
    if (retError && error) {
        *error = retError;
    }
    
    return retVal;
}

@end
