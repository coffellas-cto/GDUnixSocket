//
//  GDClientsViewController.m
//  GDUnixSocketExample
//
//  Created by Alex G on 11.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDClientsViewController.h"

@implementation GDClient
@end

@interface GDClientsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readonly, strong) NSMutableArray *clients;
@property (weak, nonatomic) IBOutlet UITableView *table;

@end

@implementation GDClientsViewController {
    GDClient *_selectedClient;
}

@synthesize clients = _clients;

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.table reloadData];
}

@end
