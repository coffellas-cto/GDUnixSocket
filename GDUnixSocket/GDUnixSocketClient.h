//
//  GDUnixSocketClient.h
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
 Connects to the socket synchronously. This is a blocking operation.
 @discussion First the address is retrieved from socket path (previously passed as an argument to designated initializer). Then it attempts to make a connection to the socket that is bound to that address. The socket is closed if any error occurs.
 
 If `autoRead` flag is set upon successful connection it immediately starts asynchronously reading on the created socket. The result is automatically sent to you if you have set a delegate object of `delegate` property.
 @param autoRead If set the reading process starts immediately after successful connection.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return YES on success or NO otherwise.
 */
- (BOOL)connectWithAutoRead:(BOOL)autoRead error:(NSError **)error;

/**
 Connects to the socket asynchronously.
 @discussion First the address is retrieved from socket path (previously passed as an argument to designated initializer). Then it attempts to make a connection to the socket that is bound to that address. The socket is closed if any error occurs.
 
 If `autoRead` flag is set, upon successful connection it immediately starts asynchronously reading on the created socket. The result is automatically sent to you if you have set a delegate object of `delegate` property.
 @param autoRead If set the reading process starts immediately after successful connection.
 @param completion Block to be called upon completion of connection operation. This block has no return value and receives one parameter: `error` if any error occurs.
 @warning Not implemented!
 */
- (void)connectWithAutoRead:(BOOL)autoRead completion:(void(^)(NSError *error))completion;

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
