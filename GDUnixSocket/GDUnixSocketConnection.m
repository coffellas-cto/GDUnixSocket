//
//  GDUnixSocketConnection.m
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDUnixSocketConnection.h"

#pragma mark - Constants

const int kGDBadSocketFD = -1;
NSString * const kGDUnixSocketErrDomain = @"com.coffellas.GDUnixSocketConnection";

#pragma mark - NSError

@implementation NSError (GDUnixSocketConnection)

+ (NSError *)gduds_errorForCode:(GDUnixSocketError)code {
    return [self gduds_errorForCode:code info:nil];
}

+ (NSError *)gduds_errorForCode:(GDUnixSocketError)code info:(NSString *)infoString {
    NSString *localizedDescription;
    switch (code) {
        case GDUnixSocketErrorBadSocket:
            localizedDescription = @"Bad socket";
            break;
        case GDUnixSocketErrorConnect:
            localizedDescription = @"Failed to connect to socket";
            break;
        case GDUnixSocketErrorSocketWrite:
            localizedDescription = [NSString stringWithFormat:@"Failed to write to socket"];
            break;
            
        default:
            localizedDescription = @"Unknown Error";
            break;
    }
    
    if (infoString.length) {
        localizedDescription = [NSString stringWithFormat:@"%@. %@", localizedDescription, infoString];
    }
    
    return [NSError errorWithDomain:kGDUnixSocketErrDomain code:code userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
}

@end

#pragma mark - GDUnixSocketConnection


@interface GDUnixSocketConnection () {
    dispatch_fd_t _fd;
}

@end


@implementation GDUnixSocketConnection

#pragma mark - Public Methods

- (ssize_t)write:(NSData *)data error:(NSError **)error {
    if (!data || !data.length) {
        return 0;
    }
    
    NSError *socketError = [self checkForBadSocket];
    if (socketError) {
        if (error) {
            *error = socketError;
        }
        
        return -1;
    }
    
    const void *buffer = data.bytes;
    size_t length = data.length;
    
    ssize_t written = write(_fd, buffer, length);
    if (-1 == written && error) {
        *error = [NSError gduds_errorForCode:GDUnixSocketErrorSocketWrite info:[self lastErrorInfo]];
    }
    
    return written;
}

- (NSError *)close {
    NSError *socketError = [self checkForBadSocket];
    if (socketError) {
        return socketError;
    }
    
    int ret_val = close(_fd);
    if (-1 == ret_val) {
        return [NSError gduds_errorForCode:GDUnixSocketErrorSocketWrite info:[self lastErrorInfo]];
    }
    
    return nil;
}

#pragma mark - Private Methods

- (NSString *)lastErrorInfo {
    int last_error = errno;
    return [NSString stringWithFormat:@"fd: %d. errno: %d. %s", _fd, last_error, strerror(last_error)];
}

- (NSError *)checkForBadSocket {
    if (_fd == kGDBadSocketFD) {
        [NSError gduds_errorForCode:GDUnixSocketErrorBadSocket];
    }
    
    return nil;
}

- (dispatch_fd_t)fd {
    return _fd;
}

#pragma mark - Life Cycle

- (instancetype)initWithSocketPath:(NSString *)socketPath {
    NSParameterAssert(socketPath);
    
    if (!socketPath.length) {
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
