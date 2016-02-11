//
//  GDUnixSocketConnection_Private.h
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDUnixSocketConnection.h"

@interface NSError (GDUnixSocketConnection)

+ (NSError *)gduds_errorForCode:(GDUnixSocketError)code;
+ (NSError *)gduds_errorForCode:(GDUnixSocketError)code info:(NSString *)infoString;

@end

@interface GDUnixSocketConnection ()

- (NSString *)lastErrorInfo;
- (NSError *)checkForBadSocket;
- (dispatch_fd_t)fd;
- (void)setFd:(dispatch_fd_t)fd;
- (NSData *)readFromSocket:(dispatch_fd_t)socket_fd error:(NSError **)error;
- (ssize_t)write:(NSData *)data toSocket:(dispatch_fd_t)socket_fd error:(NSError **)error;

@end
