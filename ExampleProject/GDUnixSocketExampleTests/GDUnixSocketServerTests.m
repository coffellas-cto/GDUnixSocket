//
//  GDUnixSocketServerTests.m
//  GDUnixSocketExample
//
//  Created by Alex G on 13.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Common.h"
#import "GDUnixSocketServer.h"

@interface GDUnixSocketServerTests : XCTestCase

@end

@implementation GDUnixSocketServerTests

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

- (void)testStartingNoClose {
    [self startedServer];
}

- (void)testClose {
    GDUnixSocketServer *server = [self startedServer];
    
    BOOL closed = [server close];
    XCTAssertTrue(closed);
}

- (void)testCloseClosed {
    GDUnixSocketServer *server = [self startedServer];
    BOOL closed = [server close];
    XCTAssertTrue(closed);
    NSError *error;
    closed = [server closeWithError:&error];
    XCTAssertTrue(closed);
    XCTAssertNil(error);
}

@end
