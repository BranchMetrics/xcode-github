//
//  XGAPreferencesViewController.m
//  xcode-github-app
//
//  Created by Edward on 5/10/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGAPreferencesViewController.h"
#import "XGASettings.h"

@interface XGAPreferencesViewController ()
@property (strong) IBOutlet XGASettings*settings;
@end

@implementation XGAPreferencesViewController

+ (instancetype) loadController {
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

@end
