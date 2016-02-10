//
//  GDUnixSocketConnection.h
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Type for enumerated error codes.
 */
typedef enum : NSUInteger {
    GDUnixSocketErrorUnknown = -3025,
    GDUnixSocketErrorBadSocket,
    GDUnixSocketErrorConnect,
    GDUnixSocketErrorSocketWrite
} GDUnixSocketError;

/** Bad socket file descriptor (-1). */
extern const int kGDBadSocketFD;

/** Domain string for errors of `GDUnixSocketConnection` class. */
extern NSString * const kGDUnixSocketErrDomain;

/**
 Base unix domain socket connection class.
 */
@interface GDUnixSocketConnection : NSObject

/** A path to socket. */
@property (nonatomic, readonly, copy) NSString *socketPath;

/**
 Initializes connection object with path to a socket.
 @param socketPath Path to unix domain socket. Cannot be `nil`.
 @return An initialized connection object. Returns `nil` if `socketPath` is empty.
 */
- (instancetype)initWithSocketPath:(NSString *)socketPath NS_DESIGNATED_INITIALIZER;

/**
 Writes data to socket synchronously.
 @param data Data to be written. If you pass `nil` or empty data, this method does nothing.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return The number of bytes written. If an error occurs, -1 is returned and an error object pointed by `error` parameter is set.
 */
- (ssize_t)write:(NSData *)data error:(NSError **)error;

/**
 Closes established connection.
 @return Error object on error, otherwise `nil`.
 */
- (NSError *)close;

@end
