//
//  GDUnixSocketTestCommon.m
//  GDUnixSocketExample
//
//  Created by Alex on 2/15/16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDUnixSocketTestCommon.h"

@implementation GDUnixSocketTestCommon

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (GDUnixSocketServer *)startedServer {
    GDUnixSocketServer *server = [[GDUnixSocketServer alloc] initWithSocketPath:gTestSocketPath];
    XCTAssertNotNil(server);
    
    NSError *error;
    BOOL started = [server listenWithError:&error];
    XCTAssertTrue(started);
    XCTAssertNil(error);
    XCTAssertEqual(server.state, GDUnixSocketStateListening);
    return server;
}

@end
