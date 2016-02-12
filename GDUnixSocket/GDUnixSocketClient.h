//
//  GDUnixSocketClient.h
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDUnixSocket.h"

@protocol GDUnixSocketClientDelegate;

/**
 Class which represents client-side Unix domain socket connection.
 */
@interface GDUnixSocketClient : GDUnixSocket

/**
 Delegate object that receives messages from `GDUnixSocketClient` object.
 @discussion Set this property before calling `connectWithError:`.
 */
@property (nonatomic, readwrite, weak) id<GDUnixSocketClientDelegate> delegate;

/**
 Connects to the socket.
 @discussion First the address is retrieved from socket path (previously passed as an argument to designated initializer). Then it attempts to make a connection to the socket that is bound to that address. The socket is closed if any error occurs.
 
 If `autoRead` flag is set upon successful connection it immediately starts asynchronously reading on the created socket. The result is automatically sent to you if you have set a delegate object of `delegate` property.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return YES on success or NO otherwise.
 */
- (BOOL)connectWithAutoRead:(BOOL)autoRead error:(NSError **)error;

@end

/**
 Protocol of `GDUnixSocketClient`'s delegate.
 */
@protocol GDUnixSocketClientDelegate <NSObject>

@optional
/**
 Called when delegate's owner receives data from server.
 @param unixSocketClient Delegate's owner, a client reading on socket connection.
 @param data Data object received from server.
 */
- (void)unixSocketClient:(GDUnixSocketClient *)unixSocketClient didReceiveData:(NSData *)data;

/**
 Called when delegate's owner tried to read data from socket but failed.
 @param unixSocketClient Delegate's owner, a client reading on socket connection.
 @param error Error object describing the problem.
 @discussion the socket is automatically closed before this method is called.
 */
- (void)unixSocketClient:(GDUnixSocketClient *)unixSocketClient didFailToReadWithError:(NSError *)error;

@end
