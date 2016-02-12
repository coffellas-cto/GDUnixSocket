//
//  GDServerViewController.m
//  GDUnixSocketExample
//
//  Created by Alex G on 11.02.16.
//  Copyright © 2016 Alexey Gordiyenko. All rights reserved.
//

#import "GDServerViewController.h"
#import "GDUnixSocketServer.h"
#import <TargetConditionals.h>

@interface GDServerViewController () <GDUnixSocketServerDelegate>

@property (weak, nonatomic) IBOutlet UIView *serverOnlineIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toggleServerStateButton;
@property (nonatomic, readwrite, assign) BOOL serverIsUp;
@property (nonatomic, readwrite, strong) GDUnixSocketServer *server;
@property (weak, nonatomic) IBOutlet UITextView *logView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashButton;

@end

@implementation GDServerViewController

#pragma mark - Actions
- (IBAction)trashTapped:(id)sender {
    self.logView.text = @"";
    self.trashButton.enabled = NO;
}

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
#if TARGET_OS_SIMULATOR
            NSString *socketPath = @"/tmp/test_socket";
#else
            NSString *socketPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_socket"];
#endif /* TARGET_OS_SIMULATOR */
            self.server = [[GDUnixSocketServer alloc] initWithSocketPath:socketPath];
            self.server.delegate = self;
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

#pragma mark - LogView

- (void)addLogLine:(NSString *)line error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorString = error ? [NSString stringWithFormat:@". Error: %@", error.localizedDescription] : @"";
        NSDate *date = [NSDate date];
        NSDateFormatter *f = [NSDateFormatter new];
        f.dateFormat = @"dd-MM HH:mm:ss";
        self.logView.text = [self.logView.text stringByAppendingString:[NSString stringWithFormat:@"\n[%@] %@%@", [f stringFromDate:date], line, errorString]];
        self.trashButton.enabled = YES;
    });
}

- (void)addLogLine:(NSString *)line {
    [self addLogLine:line error:nil];
}

#pragma mark - Communication

- (void)sendMessage:(NSString *)message toClientWithID:(NSString *)clientID {
    [self.server sendData:[message dataUsingEncoding:NSUTF8StringEncoding] toClientWithID:clientID completion:^(NSError *error, ssize_t size) {
        if (error) {
            [self addLogLine:[NSString stringWithFormat:@"Failed to send message \"%@\" to client %@", message, clientID] error:error];
        } else {
            [self addLogLine:[NSString stringWithFormat:@"Sent message \"%@\" to client %@", message, clientID]];
        }
    }];
}

#pragma mark - GDUnixSocketServerDelegate Methods

- (void)unixSocketServerDidStartListening:(GDUnixSocketServer *)unixSocketServer {
    [self addLogLine:@"Server started"];
}

- (void)unixSocketServerDidClose:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error {
    [self addLogLine:@"Server stopped" error:error];
}

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didAcceptClientWithID:(NSString *)newClientID {
    [self addLogLine:[NSString stringWithFormat:@"Accepted client %@", newClientID]];
    [self sendMessage:@"Your name?" toClientWithID:newClientID];
}

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer clientWithIDDidDisconnect:(NSString *)clientID {
    [self addLogLine:[NSString stringWithFormat:@"Client %@ disconnected", clientID]];
}

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didReceiveData:(NSData *)data fromClientWithID:(NSString *)clientID {
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self addLogLine:[NSString stringWithFormat:@"Received message from client %@\n%@", clientID, message]];
}

- (void)unixSocketServer:(GDUnixSocketServer *)unixSocketServer didFailToReadForClientID:(NSString *)clientID error:(NSError *)error {
    [self addLogLine:[NSString stringWithFormat:@"Failed to read from client %@", clientID] error:error];
}

- (void)unixSocketServerDidFailToAcceptConnection:(GDUnixSocketServer *)unixSocketServer error:(NSError *)error {
    [self addLogLine:@"Failed to accept incoming connection" error:error];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.trashButton.enabled = NO;
    
    self.serverOnlineIndicator.layer.cornerRadius = 10.0f;
    [self updateIndicator];
}

@end
