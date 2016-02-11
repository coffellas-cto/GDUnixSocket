//
//  ViewController.m
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "ViewController.h"
#import "GDUnixSocketServer.h"
#import "GDUnixSocketClient.h"

@interface ViewController () <GDUnixSocketServerDelegate> {
    GDUnixSocketServer *server;
    GDUnixSocketClient *client;
}

@end

@implementation ViewController

#pragma mark - Actions

- (IBAction)stop:(id)sender {
    [server close];
}

#pragma mark - GDUnixSocketServerDelegate

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didAcceptConnection:(GDUnixSocket *)incomingConnection {
    NSLog(@"Connection %@ accepted", incomingConnection);
}

- (void)unixSocketServerDidFailToAcceptConnection:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}

- (void)unixSocketServerDidClose:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
        
    // Do any additional setup after loading the view, typically from a nib.
    NSString *socketPath = @"/tmp/test_socket";
    server = [[GDUnixSocketServer alloc] initWithSocketPath:socketPath];
    server.delegate = self;
    if (server) {
        [server listen];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        client = [[GDUnixSocketClient alloc] initWithSocketPath:socketPath];
        if (![client connect]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *hello = @"Hello server";
                [client write:[hello dataUsingEncoding:NSUTF8StringEncoding] error:nil];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSData *streamData = nil;
                    do {
                        streamData = [client readWithError:nil];
                        if (streamData) {
                            NSString *dataString = [[NSString alloc] initWithData:streamData encoding:NSUTF8StringEncoding];
                            NSLog(@"Connection %@ received: %@", client, dataString);
                        }
                    } while (streamData);
                });
            });
        }
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
