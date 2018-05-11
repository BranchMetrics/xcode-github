//
//  AppDelegate.m
//  XcodeGitHub
//
//  Created by Edward on 3/12/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGAAppDelegate.h"
#import "XGALogViewController.h"
#import "XGAStatusViewController.h"
#import "XGAPreferencesViewController.h"

@interface XGAAppDelegate () <NSWindowDelegate>
@property (nonatomic, strong) IBOutlet XGALogViewController*logController;
@property (nonatomic, strong) IBOutlet XGAStatusViewController*statusController;
@property (nonatomic, strong) IBOutlet XGAPreferencesViewController*preferencesController;
@end

@implementation XGAAppDelegate

- (void)awakeFromNib {
    self.logController = [XGALogViewController loadController];
    self.statusController = [XGAStatusViewController loadController];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (IBAction)showStatusWindow:(id)sender {
    [self.statusController.window makeKeyAndOrderFront:self];
}

- (IBAction)showLogWindow:(id)sender {
    [self.logController.window makeKeyAndOrderFront:self];
}

- (IBAction)showPreferences:(id)sender {
    if (!self.preferencesController) {
        self.preferencesController = [XGAPreferencesViewController loadController];
    }
    self.preferencesController.window.delegate = self;
    [self.preferencesController.window makeKeyAndOrderFront:self];
}

- (BOOL)windowShouldClose:(NSWindow*)window {
    self.preferencesController = nil;
    return YES;
}

@end
