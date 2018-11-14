/**
 @file          XGAAppDelegate.m
 @package       xcode-github-app
 @brief         The xcode-github-app app delegate.

 @author        Edward Smith
 @date          March 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGAAppDelegate.h"
#import "XGALogViewController.h"
#import "XGAStatusViewController.h"
#import "XGAPreferencesViewController.h"
#import <XcodeGitHub/XcodeGitHub.h>

@interface XGAAppDelegate () <NSWindowDelegate>
@property (nonatomic, strong) IBOutlet XGALogViewController*logController;
@property (nonatomic, strong) IBOutlet XGAStatusViewController*statusController;
@property (nonatomic, strong) IBOutlet XGAPreferencesViewController*preferencesController;
@end

@implementation XGAAppDelegate

- (void)awakeFromNib {
    if (!self.logController) {
        //BNCLog(@"XcodeGitHub library version %@.", XGVersion());
        [BNCNetworkService shared].allowAnySSLCert = YES;
        self.logController = [XGALogViewController new];
        self.statusController = [XGAStatusViewController new];
    }
}

- (IBAction)showStatusWindow:(id)sender {
    [self.statusController.window makeKeyAndOrderFront:self];
}

- (IBAction)showLogWindow:(id)sender {
    [self.logController.window makeKeyAndOrderFront:self];
}

- (IBAction)showPreferences:(id)sender {
    if (!self.preferencesController) {
        self.preferencesController = [XGAPreferencesViewController new];
    }
    self.preferencesController.window.delegate = self;
    [self.preferencesController.window makeKeyAndOrderFront:self];
}

- (BOOL)windowShouldClose:(NSWindow*)window {
    self.preferencesController = nil;
    return YES;
}

@end
