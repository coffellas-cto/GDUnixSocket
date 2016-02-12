//
//  GDClientsViewController.h
//  GDUnixSocketExample
//
//  Created by Alex G on 11.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GDUnixSocketClient;

@interface GDClient : NSObject
@property NSString *name;
@property NSString *uinqueID;
@property BOOL connected;
@property GDUnixSocketClient *clientConnection;
@property NSMutableArray *serverMessages;
- (void)addServerMessage:(NSString *)message;
@end

@interface GDClientsViewController : UIViewController

@end
