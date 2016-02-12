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
    __block UITextField *textFieldKey = nil;
    __block UITextField *textFieldValue = nil;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Input message"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [self sendMessageToServer:@{textFieldKey.text.length ? textFieldKey.text : @"dummy":
                                                                                textFieldValue.text.length ? textFieldValue.text : @"dummy"}];
                                            }]];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *aTextField) {
        aTextField.placeholder = @"Key";
        textFieldKey = aTextField;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *aTextField) {
        aTextField.placeholder = @"Value";
        textFieldValue = aTextField;
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)sendMessageToServer:(NSDictionary *)message {
    NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:nil];
    [self.client.clientConnection writeData:data completion:nil];
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
        connection.delegate = self.clientDelegate;
        if ([connection connectWithAutoRead:YES error:&error]) {
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
    
    [self.client addObserver:self forKeyPath:NSStringFromSelector(@selector(serverMessages)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(connectTapped)];
    [self updateState];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(serverMessages))]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.table reloadData];
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - UITableView Delegates Methods

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellID = @"ID";
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    cell.textLabel.text = self.client.serverMessages[indexPath.row];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.client.serverMessages.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Messages from server";
}

#pragma mark - Life Cycle

- (void)dealloc {
    [self.client removeObserver:self forKeyPath:NSStringFromSelector(@selector(serverMessages))];
}

@end
