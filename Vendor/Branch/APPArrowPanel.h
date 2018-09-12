/**
 @file          APPArrowPanel.h
 @package       xcode-github-app
 @brief         A heads-up panel that draws an indicator arrow at the indicated place.

 @author        Edward Smith
 @date          July 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface APPArrowPanel : NSPanel
@property (assign) CGPoint arrowPoint;
@property (assign, readonly) BOOL isShowing;
+ (instancetype) loadPanel;
- (void) show;
- (void) dismiss;
@end

NS_ASSUME_NONNULL_END
