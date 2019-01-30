/**
 @file          XGAPreferencesViewController.h
 @package       xcode-github-app
 @brief         The preferences window view controller.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface XGAPreferencesViewController : NSViewController
+ (instancetype) new;
- (IBAction)addServerAction:(id _Nullable)sender;
@property (strong) IBOutlet NSWindow*window;
@end

NS_ASSUME_NONNULL_END
