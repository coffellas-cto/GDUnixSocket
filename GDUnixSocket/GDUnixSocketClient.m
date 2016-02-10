//
//  GDUnixSocketClient.m
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDUnixSocketClient.h"
#import "GDUnixSocketConnection_Private.h"

#include <stdio.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <string.h>

@implementation GDUnixSocketClient

#pragma mark - Public Methods

- (NSError *)connect {
    dispatch_fd_t socket_fd = socket(PF_UNIX, SOCK_STREAM, 0);
    [self setFd:socket_fd];
    if (socket_fd == kGDBadSocketFD) {
        return [NSError gduds_errorForCode:GDUnixSocketErrorBadSocket info:[self lastErrorInfo]];
    }
    
    struct sockaddr_un address;
    memset(&address, 0, sizeof(struct sockaddr_un));
    
    address.sun_family = AF_UNIX;
    snprintf(address.sun_path, PATH_MAX, "%s", [self.socketPath cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (0 != connect(socket_fd, (struct sockaddr *) &address, sizeof(struct sockaddr_un))) {
        return [NSError gduds_errorForCode:GDUnixSocketErrorConnect info:[self lastErrorInfo]];
    }
    
    return nil;
}

@end
