//
//  XGAStatusLineView.m
//  xcode-github-app
//
//  Created by Edward on 5/10/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGAStatusLineView.h"

@implementation XGAStatusLineView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Background:
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);

    // Line at top:
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(0.0, self.bounds.size.height)];
    [line lineToPoint:NSMakePoint(self.bounds.size.width, self.self.bounds.size.height)];
    [[NSColor lightGrayColor] set];
    [line setLineWidth:0.5];
    [line stroke];

    // Shadow line:
    line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(0.0, self.bounds.size.height-2)];
    [line lineToPoint:NSMakePoint(self.bounds.size.width, self.self.bounds.size.height-2)];
    [[[NSColor lightGrayColor] colorWithAlphaComponent:0.05] set];
    [line setLineWidth:1.5];
    [line stroke];
}

@end
