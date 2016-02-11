//
//  ViewController.m
//  GDUnixSocketExample
//
//  Created by Alex G on 10.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "ViewController.h"
#import "GDUnixSocketServer.h"

@interface ViewController () {
    GDUnixSocketServer *server;
}

@end

@implementation ViewController
- (IBAction)stop:(id)sender {
    [server close];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    server = [[GDUnixSocketServer alloc] initWithSocketPath:@"/tmp/test_socket"];
    if (server) {
        [server listen];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
