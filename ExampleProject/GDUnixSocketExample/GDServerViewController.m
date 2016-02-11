//
//  GDServerViewController.m
//  GDUnixSocketExample
//
//  Created by Alex G on 11.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDServerViewController.h"
#import "GDUnixSocketServer.h"

@interface GDServerViewController ()

@property (weak, nonatomic) IBOutlet UIView *serverOnlineIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toggleServerStateButton;
@property (nonatomic, readwrite, assign) BOOL serverIsUp;
@property (nonatomic, readwrite, strong) GDUnixSocketServer *server;

@end

@implementation GDServerViewController

- (void)showErrorWithTitle:(NSString *)title text:(NSString *)text {
    [[[UIAlertView alloc] initWithTitle:title message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)showErrorWithText:(NSString *)text {
    [self showErrorWithTitle:@"Error" text:text];
}

- (void)updateIndicator {
    self.toggleServerStateButton.title = self.serverIsUp ? @"Stop" : @"Start";
    self.serverOnlineIndicator.backgroundColor = self.serverIsUp ? [UIColor greenColor] : [UIColor redColor];
}

- (IBAction)toggleServerState:(id)sender {
    if (self.serverIsUp) {
        if (self.server) {
            NSError *error;
            if ([self.server closeWithError:&error]) {
                self.serverIsUp = NO;
            } else {
                [self showErrorWithTitle:@"Server stop failed" text:error.localizedDescription];
            }
        } else {
            [self showErrorWithText:@"Server object is not initialized!"];
        }
    } else {
        if (!self.server) {
            self.server = [[GDUnixSocketServer alloc] initWithSocketPath:@"/tmp/test_socket"];
        }
        
        NSError *error;
        if ([self.server listenWithError:&error]) {
            self.serverIsUp = YES;
        } else {
            [self showErrorWithTitle:@"Couldn't start server" text:error.localizedDescription];
        }
    }
    [self updateIndicator];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.serverOnlineIndicator.layer.cornerRadius = 10.0f;
    [self updateIndicator];
}

@end
