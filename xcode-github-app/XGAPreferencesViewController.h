/**
 @file          XGAPreferencesViewController.h
 @package       xcode-github-app
 @brief         The preferences window view controller.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

@interface XGAPreferencesViewController : NSViewController
+ (instancetype) loadController;
@property (strong) IBOutlet NSWindow*window;
@end
