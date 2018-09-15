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
}

- (IBAction)valueChanged:(id)sender {
    [self.settings save];
}

- (IBAction)addServerAction:(id)sender {
    self.addServerPanel = [XGAAddServerPanel new];
    [self.window beginSheet:self.addServerPanel completionHandler:^(NSModalResponse returnCode) {
        self.addServerPanel = nil;
    }];
}

@end
