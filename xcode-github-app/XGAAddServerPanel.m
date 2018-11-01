/**
 @file          XGAAddServerPanel.m
 @package       xcode-github-app
 @brief         A panel to select a server.

 @author        Edward Smith
 @date          September 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <XcodeGitHub/XcodeGitHub.h>
#import "XGAAddServerPanel.h"
#import "XGANetworkServiceBrowser.h"
#import "BNCThreads.h"

NSTimeInterval const kNetworkRefreshInterval = 7.0;

@interface XGAAddServerPanel () <XGANetworkServiceBrowserDelegate>
@property (strong) IBOutlet NSTextField *serverTextField;
@property (strong) IBOutlet NSTextField *userTextField;
@property (strong) IBOutlet NSSecureTextField *passwordTextField;
@property (strong) IBOutlet NSArrayController *serverArrayController;
@property (strong) IBOutlet NSTableView *serverTableView;
@property (strong) IBOutlet NSProgressIndicator *activityWheel;
@property (strong) IBOutlet NSButton *addButton;

@property (assign) BOOL isSearchingNetwork;
@property (strong) NSTimer*networkTimer;
@property (strong) NSDate*networkLookupDate;
@property (strong) XGANetworkServiceBrowser*networkBrowser;
@end

@implementation XGAAddServerPanel

- (instancetype) initWithServer:(XGAServer *)server {
    XGAAddServerPanel*panel = nil;
    NSArray*objects = nil;
    [[NSBundle mainBundle]
        loadNibNamed:NSStringFromClass(self.class)
        owner:nil
        topLevelObjects:&objects];
    for (panel in objects) {
        if ([panel isKindOfClass:XGAAddServerPanel.class])
            break;
    }
    if (![panel isKindOfClass:XGAAddServerPanel.class])
        panel = [[XGAAddServerPanel alloc] init];
    if (server) {
        // Copy the values, not the whole object:
        panel.server.server = server.server;
        panel.server.user = server.user;
        panel.server.password = server.password;
    }
    self = panel;

    [self startNetworkLookup];
    if (self.server.server.length) {
        self.addButton.title = @"Update";
        self.addButton.enabled = YES;
    } else {
        self.addButton.title = @"Add";
        self.addButton.enabled = NO;
    }
    return self;
}

- (void) dealloc {
    [self stopNetworkLookup];
}

- (BOOL) canBecomeKeyWindow {
    return YES;
}

- (void) controlTextDidChange:(NSNotification *)obj {
    self.addButton.enabled = (self.serverTextField.stringValue.length > 0);
}

- (IBAction)tableRowAction:(id)sender {
    NSInteger idx = self.serverTableView.selectedRow;
    if (idx < 0 || idx >= [self.serverArrayController.arrangedObjects count]) return;
    NSString*server = [self.serverArrayController.arrangedObjects objectAtIndex:idx];
    if (server) {
        self.serverTextField.stringValue = server;
        self.addButton.enabled = (self.serverTextField.stringValue.length > 0);
        [self.userTextField becomeFirstResponder];
    }
}

- (IBAction)cancel:(id)sender {
    [self stopNetworkLookup];
    self.serverArrayController = nil;
    [self.sheetParent endSheet:self returnCode:NSModalResponseCancel];
}

- (void) showAlertWithError:(NSError*)error {
    NSAlert*alert = [[NSAlert alloc] init];
    alert.messageText = [NSString stringWithFormat:@"Can't connect to '%@'", self.server.server];
    alert.informativeText = [error localizedDescription];
    alert.alertStyle = NSAlertStyleCritical;
    [alert beginSheetModalForWindow:self completionHandler:nil];
}

- (IBAction)add:(id)sender {
    self.server.server = XGACleanString(self.serverTextField.stringValue);
    self.server.user = XGACleanString(self.userTextField.stringValue);
    self.server.password = XGACleanString(self.passwordTextField.stringValue);
    if (self.server.server.length <= 0) return;

    NSError*error = nil;
    [XGXcodeBot botsForServer:self.server error:&error];
    if (error) {
        [self showAlertWithError:error];
        return;
    }
    [self stopNetworkLookup];
    self.serverArrayController = nil;
    [self.sheetParent endSheet:self returnCode:NSModalResponseOK];
}

#pragma mark - Networking

- (void) startNetworkLookup {
    @synchronized(self) {
        [self stopNetworkLookup];
        self.isSearchingNetwork = YES;
        self.networkBrowser = [[XGANetworkServiceBrowser alloc] initWithDomain:@"" service:@"_xcs2p._tcp."];
        self.networkBrowser.delegate = self;
        [self.networkBrowser startDiscovery];
        self.activityWheel.indeterminate = YES;
        [self.activityWheel startAnimation:nil];
    }
}

- (void) updateNetworkSpinner {
    NSTimeInterval t = [self.networkLookupDate timeIntervalSinceNow];
    if (t <= 0.0) {
        [self startNetworkLookup];
        return;
    }
    t = (1.0f - (t / kNetworkRefreshInterval)) * 100.0f;
    self.activityWheel.doubleValue = t;
    [self.activityWheel setNeedsDisplay:YES];
}

- (void) restartNetworkLookup {
    @synchronized(self) {
        NSLog(@"restartNetworkLookup");
        [self stopNetworkLookup];
        self.networkLookupDate = [NSDate dateWithTimeInterval:kNetworkRefreshInterval sinceDate:[NSDate date]];
        self.activityWheel.doubleValue = 0.0;
        self.activityWheel.indeterminate = NO;
        self.networkTimer =
            [NSTimer scheduledTimerWithTimeInterval:0.10
                target:self
                selector:@selector(updateNetworkSpinner)
                userInfo:nil
                repeats:YES];
    }
}

- (void) stopNetworkLookup {
    @synchronized(self) {
        [self.networkTimer invalidate];
        self.networkTimer = nil;
        self.isSearchingNetwork = NO;
        self.activityWheel.doubleValue = 0.0;
        self.activityWheel.indeterminate = YES;
        [self.activityWheel stopAnimation:nil];
    }
}

#pragma mark XGANetworkServiceBrowser Delegate

- (void) browser:(XGANetworkServiceBrowser *)browser discoveredHost:(XGANetworkServiceHost *)host {
    NSString*server = host.names.firstObject;
    if (![self.serverArrayController.arrangedObjects containsObject:server])
        [self.serverArrayController addObject:server];
}

- (void) browser:(XGANetworkServiceBrowser *)browser finishedWithError:(NSError *)error {
    [self restartNetworkLookup];
}

@end
