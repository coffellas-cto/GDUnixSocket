//
//  GDUnixSocketTests.m
//  GDUnixSocketExample
//
//  Created by Alex G on 13.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Common.h"
#import "GDUnixSocket_Private.h"

@interface GDUnixSocketTests : XCTestCase

@end

@implementation GDUnixSocketTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInitFail {
    GDUnixSocket *socket = nil;
#ifdef DEBUG
    @try {
        socket = [[GDUnixSocket alloc] init];
    }
    @catch (NSException *exception) {
        XCTAssertEqualObjects(exception.name, NSInternalInconsistencyException);
    }
    @finally {
        XCTAssertNil(socket);
    }
#else
    XCTAssertNil(socket);
#endif
    
    socket = [[GDUnixSocket alloc] initWithSocketPath:@""];
    XCTAssertNil(socket);
    
    socket = [[GDUnixSocket alloc] initWithSocketPath:@"not a path"];
    XCTAssertNil(socket);
    
    socket = [[GDUnixSocket alloc] initWithSocketPath:@"strange//path/"];
    XCTAssertNil(socket);
    
    socket = [[GDUnixSocket alloc] initWithSocketPath:@"very/long/path/very/long/path/very/long/path/very/long/path/very/long/path/very/long/path/very/long/path/very/long/path/very/long/path/very/long/path/very/long/path/very/long/path/very/long/path/very/long/path"];
    XCTAssertNil(socket);
}

- (void)testDummy {
    GDUnixSocket *socket = [[GDUnixSocket alloc] initWithSocketPath:kGDDummySocketPath];
    XCTAssertNotNil(socket);
    XCTAssertEqualObjects(kGDDummySocketPath, socket.socketPath);
}

- (void)testInit {
    GDUnixSocket *socket = [[GDUnixSocket alloc] initWithSocketPath:gTestSocketPath];
    XCTAssertNotNil(socket);
    XCTAssertEqualObjects(gTestSocketPath, socket.socketPath);
    NSString *uniqueID0 = socket.uniqueID;
    XCTAssertNotNil(uniqueID0);
    XCTAssertEqual(socket.fragmentSize, 256);
    XCTAssertEqual(socket.state, GDUnixSocketStateUnknown);
    
    socket = [[GDUnixSocket alloc] initWithSocketPath:gTestSocketPath andFragmentSize:1024];
    XCTAssertNotNil(socket);
    NSString *uniqueID1 = socket.uniqueID;
    XCTAssertNotNil(uniqueID0);
    XCTAssertNotEqualObjects(uniqueID0, uniqueID1);
    XCTAssertEqual(socket.fragmentSize, 1024);
    XCTAssertEqual(socket.state, GDUnixSocketStateUnknown);
}

- (void)testCloseUnopened {
    GDUnixSocket *socket = [[GDUnixSocket alloc] initWithSocketPath:gTestSocketPath];
    NSError *error;
    XCTAssertFalse([socket closeWithError:&error]);
    XCTAssertEqual(error.code, GDUnixSocketErrorClose);
    XCTAssertEqual(socket.state, GDUnixSocketStateUnknown);
}

- (void)testDescription {
    GDUnixSocket *socket = [[GDUnixSocket alloc] initWithSocketPath:gTestSocketPath];
    NSString *ID = socket.uniqueID;
    XCTAssertEqualObjects(socket.description, ID);
    XCTAssertEqualObjects(socket.debugDescription, ID);
}

@end
