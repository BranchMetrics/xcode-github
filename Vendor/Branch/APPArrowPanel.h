//
//  APPArrowPanel.h
//  xcode-github-app
//
//  Created by Edward on 7/29/18.
//  Copyright © 2018 Branch. All rights reserved.
//

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
