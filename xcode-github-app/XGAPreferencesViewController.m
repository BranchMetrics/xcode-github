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

@interface XGAPreferencesViewController ()
@property (strong) IBOutlet XGASettings*settings;
@property (strong) IBOutlet NSArrayController*serverArrayController;
@property (strong) IBOutlet NSTextField*gitHubTokenTextField;
@property (strong) IBOutlet NSButton *removeButton;
@property (strong) IBOutlet NSTableView *tableView;
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
    return (loaded) ? controller : nil;
}

- (void) dealloc {
    [self.settings save];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.settings = [XGASettings shared];
    self.removeButton.enabled = NO;
    self.serverArrayController.content = self.settings.servers;
}

- (IBAction)valueChanged:(id)sender {
    [self.settings save];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger idx = self.tableView.selectedRow;
    self.removeButton.enabled = (idx >= 0 && idx < [self.serverArrayController.arrangedObjects count]);
}

- (IBAction)addServerAction:(id)sender {
    self.addServerPanel = [XGAAddServerPanel new];
    [self.window beginSheet:self.addServerPanel completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            XGAServerSetting*server = [[XGAServerSetting alloc] init];
            server.server = self.addServerPanel.serverName;
            server.user = self.addServerPanel.userName;
            server.password = self.addServerPanel.password;
            [self.serverArrayController addObject:server];
        }
        self.addServerPanel = nil;
    }];
}

- (IBAction)removeServerAction:(id)sender {
    NSInteger idx = self.tableView.selectedRow;
    if (idx >= 0 && idx < [self.serverArrayController.arrangedObjects count]) {
        [self.serverArrayController removeObjectAtArrangedObjectIndex:idx];
    }
}

@end
