/**
 @file          XGAStatusViewController.h
 @package       xcode-github-app
 @brief         The view controller for the status window.

 @author        Edward Smith
 @date          March 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface XGAStatusViewController : NSViewController
+ (instancetype) new;
@property (strong) IBOutlet NSWindow*window;
@end

NS_ASSUME_NONNULL_END
