/**
 @file          XGAView.m
 @package       xcode-github-app
 @brief         A view with some convenient options.

 @author        Edward Smith
 @date          July 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGAView.h"

@implementation XGAView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
//    if (self.backgroundColor)
//        [self.backgroundColor set];
//    else
        [[NSColor clearColor] set];
    NSRectFill(dirtyRect);
}

@end
