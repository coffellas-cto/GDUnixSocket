//
//  GDUnixSocketClient.h
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDUnixSocketConnection.h"

/**
 Class which represents client-side Unix domain socket connection.
 */
@interface GDUnixSocketClient : GDUnixSocketConnection

/**
 Connects to the socket.
 @discussion First the address is retrieved from socket path (previously passed as an argument to designated initializer). Then it attempts to make a connection to the socket that is bound to that address. The socket is closed if any error occurs.
 @return An error object if any error occured or `nil` otherwise.
 */
- (NSError *)connect;

@end
