//
//  APPArrowPanel.m
//  xcode-github-app
//
//  Created by Edward on 7/29/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "APPArrowPanel.h"

@implementation APPArrowPanel

+ (instancetype) windowWithContentViewController:(NSViewController *)contentViewController
                                      arrowPoint:(CGPoint)point {
    APPArrowPanel*window = [super windowWithContentViewController:contentViewController];
    return window;
}

@end
