//
//  GDUnixSocketServer.h
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

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
 @return An error object if any error occured or `nil` otherwise.
 */
- (NSError *)listenWithMaxConnections:(int)maxConnections;

/**
 Sends `listenWithMaxConnections:` message with 0 as an argument.
 @see - (NSError *)listenWithMaxConnections:(NSInteger)maxConnections;
 */
- (NSError *)listen;

@end

/**
 Protocol of `GDUnixSocketServer`'s delegate.
 */
@protocol GDUnixSocketServerDelegate <NSObject>
@optional
/**
 Called when delegate's owner closes its socket.
 @param unixSocketServer Delegate's owner, a server listening on incoming connections.
 @param error Error object describing the problem or `nil` if closed successfully.
 */
- (void)unixSocketServerDidClose:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error;

/**
 Called when delegate's owner accepts a new incoming connection.
 @param unixSocketServer Delegate's owner, a server listening on incoming connections.
 @param newConnectionID A new connection unique identifier.
 */
- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didAcceptConnectionWithID:(NSString *)newConnectionID;

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didFailToReadForConnectionID:(NSString *)newConnectionID error:(NSError *)error;

/**
 Called when delegate's owner failed to accept connection.
 @discussion Delegate's owner first calls this method, then closes its socket.
 @param unixSocketServer Delegate's owner, a server listening on incoming connections.
 @param error Error object describing the problem.
 */
- (void)unixSocketServerDidFailToAcceptConnection:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error;

@end