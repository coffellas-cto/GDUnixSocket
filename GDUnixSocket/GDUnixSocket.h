//
//  GDUnixSocket.h
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

#import <Foundation/Foundation.h>

#ifdef GD_UNIX_SOCKET_DEBUG
#define GDUnixSocketLog(format, ...) NSLog((@"" format), ##__VA_ARGS__)
#else
#define GDUnixSocketLog(...)
#endif

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

/** Type for socket state. */
typedef enum : NSUInteger {
    GDUnixSocketStateUnknown,
    GDUnixSocketStateConnected,
    GDUnixSocketStateDisconnected,
    GDUnixSocketStateListening
} GDUnixSocketState;

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

/** Describes socket's state. */
@property (atomic, readonly, assign) GDUnixSocketState state;

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
 Closes established connection. Does nothing if socket is already closed.
 @return YES on success, NO otherwise.
 */
- (BOOL)close;

/**
 Closes established connection. Does nothing if socket is already closed.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return YES on success, NO otherwise.
 */
- (BOOL)closeWithError:(NSError **)error;

@end
