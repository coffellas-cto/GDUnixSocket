//
//  GDUnixSocketServer.h
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

#import "GDUnixSocket.h"

/** Default number of simultaneous connections (5). */
extern const int kGDUnixSocketServerMaxConnectionsDefault;

@protocol GDUnixSocketServerDelegate;

/**
 Class which represents server-side Unix domain socket connection.
 */
@interface GDUnixSocketServer : GDUnixSocket

/** Delegate object that receives messages from `GDUnixSocketServer` object. */
@property (nonatomic, readwrite, weak) id<GDUnixSocketServerDelegate> delegate;

/**
 Listens for incoming connections on the socket.
 @discussion First the address is retrieved from socket path (previously passed as an argument to designated initializer). Then it binds the socket: assigns that address. Finally it starts listening on the socket, that is, marks it as a socket that will be used to accept incoming connection requests. The socket is closed if any error occurs.
 @param maxConnections The maximum simultaneous connections count. If 0 is passed `kGDUnixSocketServerMaxConnectionsDefault` value is used (which is 5). If a connection request arrives when the queue is full, the client may receive an error with an indication of ECONNREFUSED or, if the underlying protocol supports retransmission, the request may be ignored so that a later reattempt at connection succeeds.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return YES on success, NO otherwise.
 */
- (BOOL)listenWithMaxConnections:(int)maxConnections error:(NSError **)error;

/**
 Sends `listenWithMaxConnections:error:` message with 0 as an argument.
 @see - (BOOL)listenWithMaxConnections:(int)maxConnections error:(NSError **)error;
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return YES on success, NO otherwise.
 */
- (BOOL)listenWithError:(NSError **)error;

/**
 Writes data to socket associated with client synchronously.
 @param data Data to be written. If you pass `nil` or empty data, this method does nothing.
 @param clientID A client connection unique identifier.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return The number of bytes written. If an error occurs, -1 is returned and an error object pointed by `error` parameter is set.
 */
- (ssize_t)sendData:(NSData *)data toClientWithID:(NSString *)clientID error:(NSError **)error;

/**
 Writes data to socket associated with client asynchronously.
 @param data Data to be written. If you pass `nil` or empty data, this method does nothing.
 @param clientID A client connection unique identifier.
 @param completion Block to be called upon completion of writing operation. This block has no return value and receives two parameters: `error` if any error occurs and `size` which represents the number of bytes written.
 */
- (void)sendData:(NSData *)data toClientWithID:(NSString *)clientID completion:(void(^)(NSError *error, ssize_t size))completion;

@end

/**
 Protocol of `GDUnixSocketServer`'s delegate.
 */
@protocol GDUnixSocketServerDelegate <NSObject>
@optional
/**
 Called when delegate's owner starts listening on its socket.
 @param unixSocketServer Delegate's owner, a server listening on incoming connections.
 */
- (void)unixSocketServerDidStartListening:(GDUnixSocketServer *)unixSocketServer;

/**
 Called when delegate's owner closes its socket.
 @param unixSocketServer Delegate's owner, a server listening on incoming connections.
 @param error Error object describing the problem or `nil` if closed successfully.
 */
- (void)unixSocketServerDidClose:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error;

/**
 Called when delegate's owner accepts a new incoming connection.
 @param unixSocketServer Delegate's owner, a server listening on incoming connections.
 @param newClientID A new client connection unique identifier.
 */
- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didAcceptClientWithID:(NSString *)newClientID;

/**
 Called when one of the clients connections closes.
 @param unixSocketServer Delegate's owner, a server listening on incoming connections.
 @param clientID A client connection unique identifier.
 */
- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer clientWithIDDidDisconnect:(NSString *)clientID;

/**
 Called when delegate's owner receives data from a particular client.
 @param unixSocketServer Delegate's owner, a server listening on incoming connections.
 @param data Data object received from client.
 @param clientID A client connection unique identifier.
 */
- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didReceiveData:(NSData *)data fromClientWithID:(NSString *)clientID;

/**
 Called when delegate's owner failed to data from socket associated with particular client.
 @param unixSocketServer Delegate's owner, a server listening on incoming connections.
 @param clientID A client connection unique identifier.
 @param error Error object describing the problem.
 */
- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didFailToReadForClientID:(NSString *)clientID error:(NSError *)error;

/**
 Called when delegate's owner failed to accept connection.
 @discussion Delegate's owner first calls this method, then closes its socket.
 @param unixSocketServer Delegate's owner, a server listening on incoming connections.
 @param error Error object describing the problem.
 */
- (void)unixSocketServerDidFailToAcceptConnection:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error;

@end