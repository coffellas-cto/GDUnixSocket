# GDUnixSocket
Unix Domain Sockets for Objective-C

##About
Unix domain sockets are designed specifically for local interprocess communication. See [this](http://man7.org/linux/man-pages/man7/unix.7.html) for clarification.

`GDUnixSocket` framework is an Objective-C object-oriented wrapper around unix sockets which allows you to abstract away from file descriptors and system calls. You can also use it for communication between any entities within one process.

All calls are blocking for now. But there are asynchronous variants of methods which call blocking operations on concurrent queues. See "Usage" for further details.

There is a complete example project for your convinience.

##Usage
The framework consists of three main classes:

* `GDUnixSocket` - base class. Generally you don't use it as it implements only read/write operations but not the actual creation of a socket.
* `GDUnixSocketServer` - use it for creating a server.
* `GDUnixSocketClient` - use it for creating a client.

*For the complete documentation of every method see source code*.

###1. Initialization

The main channel of communication for both of these working classes is the actual file located somewhere in your file system. In order to initialize client or server you have to pass a path to this file as a parameter to initializer. For example:

```
NSString *socketPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_socket"];
GDUnixSocketClient *client = [[GDUnixSocketClient alloc] initWithSocketPath:socketPath];
```

Note that server and its clients all should be initialized with the same path.

Beware that your process **must** have access rights to read and write to the directory where your new socket file is located. Otherwise the listening/connecting process would just fail.

Also note that path to the socket is limited to the size of `sun_path` field of `struct	sockaddr_un` imported from `<sys/un.h>` file. Check its value for your platform.

###2. Starting a server
Follow this rule: first you run server, then you connect clients. In order to start a server you have to create and and initialize an object of `GDUnixSocketServer` class as described in **1**.

Upon success of initialization you can start listening on newly created socket by calling one of the `listenWithMaxConnections:error:` or `listenWithError:` methods:

```
self.server = [[GDUnixSocketServer alloc] initWithSocketPath:socketPath];
self.server.delegate = self;
NSError *error;
if ([self.server listenWithError:&error]) {
    self.serverIsUp = YES;
} else {
    [self showErrorWithTitle:@"Couldn't start server" text:error.localizedDescription];
}
```

You can set a delegate object for your server (which conforms to `GDUnixSocketServerDelegate` protocol) to observe different events including but not limited to: new client connected, a client disconnected, server stopped, etc. For complete listing of these methods see **6**.

###3. Connecting a client.
After your server is set up and listening you can freely create a client (as described in **1**) and try to connect to server:

```
NSError *error;
client.delegate = self.clientDelegate;
if ([client connectWithAutoRead:YES error:&error]) {
    [self setIndicatorConnected:YES];
} else {
    [self showErrorWithTitle:@"Can't connect" text:error.localizedDescription];
}
```

If `autoRead` flag is set, upon successful connection it immediately starts asynchronously reading on the created socket. The result is automatically sent to you if you have set a delegate object of `delegate` property.

Setting a delegate object which conforms to `GDUnixSocketClientDelegate` protocol allows you to receive data from server and observe reading errors. See **6** for its methods.

###4. Writing
You can write data to a **client** connection using synchronous `writeData:error:` or asynchronous `writeData:completion:`.

There is no meaning in writing data to **server** connection, but you can send data to one of the clients connected to that server.

When a new client connects, your server's delegate receives a message `unixSocketServer:didAcceptClientWithID:` where the second parameter `newClientID` is a new client connection unique identifier. You also receive a client ID every time delegate's method `unixSocketServer:didReceiveData:fromClientWithID:` is called.

So, you can send data to a client described by this identifier by calling `sendData:toClientWithID:error:` method or its asynchronous friend `sendData:toClientWithID:completion:` on your server object:

```
- (void)sendMessage:(NSString *)message toClientWithID:(NSString *)clientID {
    [self.server sendData:[message dataUsingEncoding:NSUTF8StringEncoding] toClientWithID:clientID completion:^(NSError *error, ssize_t size) {
        if (error) {
            [self addLogLine:[NSString stringWithFormat:@"Failed to send message \"%@\" to client %@", message, clientID] error:error];
        } else {
            [self addLogLine:[NSString stringWithFormat:@"Sent message \"%@\" to client %@", message, clientID]];
        }
    }];
}
```

###5. Reading
You can explicitly call `readWithError:` or `readWithCompletion:` on both your client and server object in order to read a incoming data.

You generally don't have to do so for servers and for a client which was connected with `autoRead` flag set. You rather set delegate objects and receive data when the corresponding methods are called. See **6** for the list of methods supported by delegates.

###6. Protocols
Protocol of `GDUnixSocketClient`'s delegate:

```
@protocol GDUnixSocketClientDelegate <NSObject>
@optional
- (void)unixSocketClient:(GDUnixSocketClient *)unixSocketClient didReceiveData:(NSData *)data;
- (void)unixSocketClient:(GDUnixSocketClient *)unixSocketClient didFailToReadWithError:(NSError *)error;
@end
```

Protocol of `GDUnixSocketServer`'s delegate:

```
@protocol GDUnixSocketServerDelegate <NSObject>
@optional
- (void)unixSocketServerDidStartListening:(GDUnixSocketServer *)unixSocketServer;
- (void)unixSocketServerDidClose:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error;
- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didAcceptClientWithID:(NSString *)newClientID;
- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer clientWithIDDidDisconnect:(NSString *)clientID;
- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didReceiveData:(NSData *)data fromClientWithID:(NSString *)clientID;
- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didFailToReadForClientID:(NSString *)clientID error:(NSError *)error;
- (void)unixSocketServerDidFailToAcceptConnection:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error;
@end
```

###7. Closing
In order to close server or client you just call `close` or `closeWithError:`.

##TODO
- It would be nice to have a non-blocking implementation rather then calling blocking functions asynchronously on dispatch queues
- Last error is retieved using `errno`, need to switch to `getsockopt(..., ..., SO_ERROR, ..., ...)`

##License
Published under MIT license. If you have any feature requests, please create an issue. Smart pull requests are also welcome.

Copyright (c) 2016 Alex Gordiyenko
