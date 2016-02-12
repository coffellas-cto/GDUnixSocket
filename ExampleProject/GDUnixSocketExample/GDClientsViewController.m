//
//  GDClientsViewController.m
//  GDUnixSocketExample
//
//  Created by Alex G on 11.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDClientsViewController.h"
#import "GDUnixSocketClient.h"

@implementation GDClient
- (instancetype)init
{
    self = [super init];
    if (self) {
        _serverMessages = [NSMutableArray new];
    }
    return self;
}
- (void)addServerMessage:(NSString *)message {
    [self willChangeValueForKey:NSStringFromSelector(@selector(serverMessages))];
    [self.serverMessages addObject:message];
    [self didChangeValueForKey:NSStringFromSelector(@selector(serverMessages))];
}
@end

@interface GDClientsViewController () <UITableViewDelegate, UITableViewDataSource, GDUnixSocketClientDelegate>

@property (nonatomic, readonly, strong) NSMutableArray *clients;
@property (weak, nonatomic) IBOutlet UITableView *table;

@end

@implementation GDClientsViewController {
    GDClient *_selectedClient;
}

@synthesize clients = _clients;

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(connected))]) {
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - GDUnixSocketClientDelegate

- (void)unixSocketClient:(GDUnixSocketClient *)unixSocketClient didReceiveData:(NSData *)data {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString *dataSting = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // For now we just loop through clients (I know it's not optimal but it's for now, pleaase)
    for (GDClient *client in self.clients) {
        if ([client.clientConnection.uniqueID isEqualToString:unixSocketClient.uniqueID]) {
            [client addServerMessage:dataSting];
            break;
        }
    }
}

- (void)unixSocketClient:(GDUnixSocketClient *)unixSocketClient didFailToReadWithError:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark - Stuff

- (NSMutableArray *)clients {
    if (!_clients) {
        _clients = [NSMutableArray new];
    }
    
    return _clients;
}

- (IBAction)addClientTapped:(id)sender {
    __block UITextField *textField = nil;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Input client name"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [self addClientWithName:textField.text];
                                            }]];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *aTextField) {
        aTextField.placeholder = @"John Doe";
        textField = aTextField;
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)addClientWithName:(NSString *)name {
    GDClient *newClient = [GDClient new];
    newClient.name = name.length ? name : @"John Doe";
    [newClient addObserver:self forKeyPath:NSStringFromSelector(@selector(connected)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];
    [self.clients addObject:newClient];
    [self.table reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"clientsCell" forIndexPath:indexPath];
    GDClient *client = self.clients[indexPath.row];
    cell.textLabel.text = client.name;
    cell.detailTextLabel.text = client.connected ? @"Connected" : @"Disconnected";
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.clients.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    _selectedClient = self.clients[indexPath.row];
    [self performSegueWithIdentifier:@"clientSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id dst = segue.destinationViewController;
    [dst performSelector:@selector(setClient:) withObject:_selectedClient];
    [dst performSelector:@selector(setClientDelegate:) withObject:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.table reloadData];
}

- (void)dealloc
{
    [self.clients removeObserver:self
            fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.clients.count - 1)]
                      forKeyPath:NSStringFromSelector(@selector(connected))];
}

@end
