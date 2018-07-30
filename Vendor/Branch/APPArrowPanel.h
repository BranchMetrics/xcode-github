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
+ (instancetype) windowWithContentViewController:(NSViewController *)contentViewController
                                      arrowPoint:(CGPoint)point;
@property (assign) CGPoint arrowPoint;
@end

NS_ASSUME_NONNULL_END
