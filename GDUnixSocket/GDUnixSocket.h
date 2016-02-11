//
//  GDUnixSocket.h
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Type for enumerated error codes. */
typedef enum : NSUInteger {
    GDUnixSocketErrorUnknown = -3025,
    GDUnixSocketErrorBadSocket,
    GDUnixSocketErrorBind,
    GDUnixSocketErrorListen,
    GDUnixSocketErrorAccept,
    GDUnixSocketErrorUnlink,
    GDUnixSocketErrorConnect,
    GDUnixSocketErrorSocketWrite,
    GDUnixSocketErrorSocketRead,
    GDUnixSocketErrorClose
} GDUnixSocketError;

/** Bad socket file descriptor (-1). */
extern const int kGDBadSocketFD;

/** Domain string for errors of `GDUnixSocket` class. */
extern NSString * const kGDUnixSocketErrDomain;

/**
 Base Unix domain socket connection class.
 */
@interface GDUnixSocket : NSObject

/** A path to socket. */
@property (nonatomic, readonly, copy) NSString *socketPath;

/** A unique socket connection identifier. */
@property (nonatomic, readonly, copy) NSString *uniqueID;

/**
 Initializes connection object with path to a socket.
 @param socketPath Path to Unix domain socket. Cannot be `nil`.
 @return An initialized connection object. Returns `nil` if `socketPath` is empty OR longer than 103 characters (Unix socket path length).
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
 Reads data from socket synchronously.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return data object read from socket or `nil` if any error occurs.
 */
- (NSData *)readWithError:(NSError **)error;

/**
 Closes established connection.
 @return Error object on error, otherwise `nil`.
 */
- (NSError *)close;

@end
