/**
 @file          XGAPreferencesViewController.m
 @package       xcode-github-app
 @brief         The preferences window view controller.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGAPreferencesViewController.h"
#import "XGASettings.h"
#import "XGAAddServerPanel.h"
#import <XcodeGitHub/BNCLog.h>

@interface XGAPreferencesViewController ()
@property (strong) IBOutlet XGASettings*settings;
@property (strong) IBOutlet NSDictionaryController*serverDictionaryController;
@property (strong) IBOutlet NSTextField*gitHubTokenTextField;
@property (strong) IBOutlet NSButton *removeButton;
@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSNumberFormatter *refreshTimeFormatter;
@property (strong) XGAAddServerPanel *addServerPanel;
@end

@implementation XGAPreferencesViewController

+ (instancetype) new {
    XGAPreferencesViewController*controller = [[XGAPreferencesViewController alloc] init];
    BOOL loaded =
        [[NSBundle mainBundle]
            loadNibNamed:NSStringFromClass(self)
            owner:controller
            topLevelObjects:nil];
    BNCLogAssert(loaded && controller);
    return controller;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    @synchronized (self) {
        if (self.settings) return;
        self.settings = [XGASettings shared];
        self.removeButton.enabled = NO;
        //self.serverDictionaryController.content = self.settings.servers;
        self.refreshTimeFormatter.multiplier = @(1.0/60.0);
        self.refreshTimeFormatter.minimumFractionDigits = 0;
        self.refreshTimeFormatter.maximumFractionDigits = 0;
    }
}

- (IBAction)valueChanged:(id)sender {
    [self.settings save];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger idx = self.tableView.selectedRow;
    self.removeButton.enabled =
        (idx >= 0 && idx < [self.serverDictionaryController.arrangedObjects count]);
}

- (IBAction)addServerAction:(id)sender {
    [self showServer:nil];
}

- (IBAction)serverDoubleAction:(id)sender {
    NSInteger idx = self.tableView.selectedRow;
    if (idx >= 0 && idx < [self.serverDictionaryController.arrangedObjects count]) {
        NSDictionaryControllerKeyValuePair*pair =
            [self.serverDictionaryController.arrangedObjects objectAtIndex:idx];
        XGAServer*server = pair.value;
        [self showServer:server];
    }
}

- (void) showServer:(XGAServer*)server {
    if (!server) server = [[XGAServer alloc] init];
    self.addServerPanel = [[XGAAddServerPanel alloc] initWithServer:server];
    [self.window beginSheet:self.addServerPanel completionHandler:^(NSModalResponse returnCode) {
        __auto_type result = self.addServerPanel.server;
        if (returnCode == NSModalResponseOK &&
            result.server.length &&
            self.settings.servers[result.server] == nil) {
            self.settings.servers[result.server] = result;
            [self.settings save];
            NSDictionaryControllerKeyValuePair*pair = [self.serverDictionaryController newObject];
            pair.key = result.server;
            pair.value = result;
            [self.serverDictionaryController addObject:pair];
        }
        self.addServerPanel = nil;
    }];
}

- (IBAction)removeServerAction:(id)sender {
    NSInteger idx = self.tableView.selectedRow;
    if (idx >= 0 && idx < [self.serverDictionaryController.arrangedObjects count]) {
        [self.serverDictionaryController removeObjectAtArrangedObjectIndex:idx];
        [self.settings save];
        [self tableViewSelectionDidChange:nil];
    }
}

- (IBAction) resetSettingsAction:(id)sender {
    [self.settings clear];
    [self.settings save];
    self.serverDictionaryController.content = self.settings.servers;
}

@end
