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

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didAcceptClientWithID:(NSString *)newClientID {
    NSLog(@"Connection %@ accepted", newClientID);
}

- (void)unixSocketServerDidFailToAcceptConnection:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}

- (void)unixSocketServerDidClose:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didFailToReadForClientID:(NSString *)clientID error:(NSError *)error {
    NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, clientID, error);
}

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didReceiveData:(NSData *)data fromClientWithID:(NSString *)clientID {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, clientID, dataString);
    if ([dataString rangeOfString:@"hello" options:NSCaseInsensitiveSearch].length) {
        [unixSocketServer sendData:[@"Well, well, well..." dataUsingEncoding:NSUTF8StringEncoding] toClientWithID:clientID error:nil];
    }
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
                        if (streamData.length) {
                            NSString *dataString = [[NSString alloc] initWithData:streamData encoding:NSUTF8StringEncoding];
                            NSLog(@"Connection %@ received: %@", client, dataString);
                        }
                    } while (streamData.length);
                    [client close];
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
