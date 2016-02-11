//
//  GDClientViewController.m
//  GDUnixSocketExample
//
//  Created by Alex G on 11.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDClientViewController.h"
#import "GDClientsViewController.h"
#import "GDUnixSocketClient.h"
#import <TargetConditionals.h>

@interface GDClientViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *table;

@end

@implementation GDClientViewController

#pragma mark - Stuff

- (IBAction)messageToServerTapped:(id)sender {
}

- (void)showErrorWithTitle:(NSString *)title text:(NSString *)text {
    [[[UIAlertView alloc] initWithTitle:title message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)showErrorWithText:(NSString *)text {
    [self showErrorWithTitle:@"Error" text:text];
}

- (void)connectTapped {
    GDUnixSocketClient *connection = self.client.clientConnection;
    if (self.client.connected) {
        if (!connection) {
            [self showErrorWithText:@"No connection object found!"];
            return;
        }
        
        NSError *error;
        if ([connection closeWithError:&error]) {
            self.client.connected = NO;
        } else {
            [self showErrorWithTitle:@"Can't close connection" text:error.localizedDescription];
        }
    } else {
        if (!connection) {
#if TARGET_OS_SIMULATOR
            NSString *socketPath = @"/tmp/test_socket";
#else
            NSString *socketPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_socket"];
#endif /* TARGET_OS_SIMULATOR */
            connection = [[GDUnixSocketClient alloc] initWithSocketPath:socketPath];
        }
        
        NSError *error;
        if ([connection connectWithError:&error]) {
            self.client.connected = YES;
            self.client.clientConnection = connection;
        } else {
            [self showErrorWithTitle:@"Can't connect" text:error.localizedDescription];
        }
    }
    
    [self updateState];
}

- (void)updateState {
    self.navigationItem.rightBarButtonItem.title = self.client.connected ? @"Disconnect" : @"Connect";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.client.name;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(connectTapped)];
    [self updateState];
}

#pragma mark - UITableView Delegates Methods

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellID = @"ID";
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.client.serverMessages.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Messages from server";
}

@end
