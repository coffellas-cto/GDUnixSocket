//
//  GDUnixSocketTestCommon.h
//  GDUnixSocketExample
//
//  Created by Alex on 2/15/16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#ifndef GDUnixSocketTestCommon_h
#define GDUnixSocketTestCommon_h

#import <XCTest/XCTest.h>
#import "GDUnixSocketServer.h"
#import "Common.h"

@class GDUnixSocketServer;

@interface GDUnixSocketTestCommon : XCTestCase

- (GDUnixSocketServer *)startedServer;

@end


#endif /* GDUnixSocketTestCommon_h */
