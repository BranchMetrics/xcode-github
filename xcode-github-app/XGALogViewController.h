/**
 @file          XGALogViewController.h
 @package       xcode-github-app
 @brief         The log window view controller.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface XGALogViewController : NSViewController
+ (void) startLog;
+ (instancetype) loadController;
@property (strong) IBOutlet NSWindow*window;
@end

NS_ASSUME_NONNULL_END
