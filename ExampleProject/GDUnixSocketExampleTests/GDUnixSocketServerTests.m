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
#import "GDUnixSocketTestCommon.h"

@interface GDUnixSocketServerTests : GDUnixSocketTestCommon <GDUnixSocketServerDelegate> {
    GDUnixSocketServer *_server;
}

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

- (void)testStartingNoClose {
    _server = [[GDUnixSocketServer alloc] initWithSocketPath:gTestSocketPath];
    XCTAssertNotNil(_server);
    
    _server.delegate = self;
    
    NSError *error = [NSError errorWithDomain:@"" code:-1000 userInfo:nil];
    BOOL started = [_server listenWithError:&error];
    XCTAssertTrue(started);
    XCTAssertNil(error);
    XCTAssertEqual(_server.state, GDUnixSocketStateListening);
    
    error = [NSError errorWithDomain:@"" code:-1000 userInfo:nil];
    BOOL closed = [_server closeWithError:&error];
    XCTAssertTrue(closed);
    XCTAssertNil(error);
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
    NSError *error = [NSError errorWithDomain:@"" code:-1000 userInfo:nil];
    closed = [server closeWithError:&error];
    XCTAssertTrue(closed);
    XCTAssertNil(error);
}

#pragma mark - 

- (void)unixSocketServerDidStartListening:(GDUnixSocketServer *)unixSocketServer {
    XCTAssertTrue(_server == unixSocketServer);
}

- (void)unixSocketServerDidClose:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error {
    XCTAssertNil(error);
    XCTAssertTrue(_server == unixSocketServer);
}

@end
