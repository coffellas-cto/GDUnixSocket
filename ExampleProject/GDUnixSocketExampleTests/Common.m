//
//  Common.m
//  GDUnixSocketExample
//
//  Created by Alex G on 13.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "Common.h"

#if TARGET_OS_SIMULATOR
NSString * const gTestSocketPath = @"/tmp/test_socket";
#else
NSString * const gTestSocketPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_socket"];
#endif /* TARGET_OS_SIMULATOR */