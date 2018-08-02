//
//  XGAView.m
//  xcode-github-app
//
//  Created by Edward on 7/31/18.
//  Copyright © 2018 Branch. All rights reserved.
//

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
