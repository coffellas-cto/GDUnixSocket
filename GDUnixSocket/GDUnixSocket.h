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
    GDUnixSocketErrorClose,
    GDUnixSocketErrorUnknownClient
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
 The maximum size of fragment read when `readWithError:` is called. Default is 256.
 @see - (ssize_t)write:(NSData *)data error:(NSError **)error
 */
@property (atomic, readwrite, assign) size_t fragmentSize;

/**
 Calls `initWithSocketPath:andFragmentSize:` with default fragment size.
 */
- (instancetype)initWithSocketPath:(NSString *)socketPath;

/**
 Initializes connection object with path to a socket.
 @param socketPath Path to Unix domain socket. Cannot be `nil`.
 @param fragmentSize The maximum size of fragment read when `readWithError:` is called.
 @return An initialized connection object. Returns `nil` if `socketPath` is empty OR longer than 103 characters (Unix socket path length).
 */
- (instancetype)initWithSocketPath:(NSString *)socketPath andFragmentSize:(size_t)fragmentSize NS_DESIGNATED_INITIALIZER;

/**
 Writes data to socket synchronously.
 @param data Data to be written. If you pass `nil` or empty data, this method does nothing.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return The number of bytes written. If an error occurs, -1 is returned and an error object pointed by `error` parameter is set.
 */
- (ssize_t)writeData:(NSData *)data error:(NSError **)error;

/**
 Writes data to socket asynchronously.
 @param data Data to be written. If you pass `nil` or empty data, this method does nothing.
 @param completion Block to be called upon completion of writing operation. This block has no return value and receives two parameters: `error` if any error occurs and `size` which represents the number of bytes written.
 */
- (void)writeData:(NSData *)data completion:(void(^)(NSError *error, ssize_t size))completion;

/**
 Reads data from socket synchronously.
 @discussion Data is read by chunks of size assigned to `fragmentSize` property.
 @see fragmentSize
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return data Data object read from socket or `nil` if any error occurs.
 */
- (NSData *)readWithError:(NSError **)error;

/**
 Reads data from socket asynchronously.
 @discussion Data is read by chunks of size assigned to `fragmentSize` property.
 @see fragmentSize
 @param completion Block to be called upon completion of reading operation. This block has no return value and receives two parameters: `error` if any error occurs and `data` - data object read from socket.
 */
- (void)readWithCompletion:(void(^)(NSError *error, NSData *data))completion;

/**
 Closes established connection.
 @return YES on success, NO otherwise.
 */
- (BOOL)close;

/**
 Closes established connection.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return YES on success, NO otherwise.
 */
- (BOOL)closeWithError:(NSError **)error;

@end
