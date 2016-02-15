//
//  GDUnixSocketClientTest.m
//  GDUnixSocketExample
//
//  Created by Alex on 2/15/16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GDUnixSocketServer.h"
#import "GDUnixSocketClient.h"
#import "GDUnixSocketTestCommon.h"

@interface GDUnixSocketClientTest : GDUnixSocketTestCommon

@end

@implementation GDUnixSocketClientTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testConnectAutoReadFailure {
    GDUnixSocketClient *client = [[GDUnixSocketClient alloc] initWithSocketPath:gTestSocketPath];
    XCTAssertNotNil(client);
    
    NSError *error;
    BOOL connected = [client connectWithAutoRead:YES error:&error];
    XCTAssertFalse(connected);
    XCTAssertEqual(error.code, GDUnixSocketErrorConnect);
}

- (void)testConnectAutoRead {
    [self startedServer];
    GDUnixSocketClient *client = [[GDUnixSocketClient alloc] initWithSocketPath:gTestSocketPath];
    XCTAssertNotNil(client);
    
    NSError *error;
    BOOL connected = [client connectWithAutoRead:YES error:&error];
    XCTAssertTrue(connected);
    XCTAssertNil(error);
    
    BOOL closed = [client closeWithError:&error];
    XCTAssertTrue(closed);
    XCTAssertNil(error);
}

@end
