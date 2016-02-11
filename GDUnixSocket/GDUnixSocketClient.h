//
//  GDUnixSocketClient.h
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDUnixSocket.h"

/**
 Class which represents client-side Unix domain socket connection.
 */
@interface GDUnixSocketClient : GDUnixSocket

/**
 Connects to the socket.
 @discussion First the address is retrieved from socket path (previously passed as an argument to designated initializer). Then it attempts to make a connection to the socket that is bound to that address. The socket is closed if any error occurs.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. Can be `nil`.
 @return YES on success or NO otherwise.
 */
- (BOOL)connectWithError:(NSError **)error;

@end
