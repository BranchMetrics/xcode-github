//
//  XGAStatusPanel.m
//  xcode-github-app
//
//  Created by Edward on 7/29/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGAStatusPanel.h"
#import "BNCGeometry.h"

@interface NSWindow (XGA)
- (NSPoint) convertPointToScreen:(NSPoint)point;
@end

@implementation NSWindow (XGA)

- (NSPoint) convertPointToScreen:(NSPoint)point {
    NSRect r = [self convertRectToScreen:NSMakeRect(point.x, point.y, 0.0, 0.0)];
    return r.origin;
}

@end

#pragma XGAStatusPanel

@interface XGAStatusPanel ()
@property (strong) XGAStatusPanel*selfReference;
@property (strong) id eventMonitor;
@end

@implementation XGAStatusPanel

+ (instancetype) loadPanel {
    NSArray*objects = nil;
    [[NSBundle mainBundle]
        loadNibNamed:NSStringFromClass(self)
        owner:nil
        topLevelObjects:&objects];
    for (XGAStatusPanel*panel in objects) {
        if ([panel isKindOfClass:XGAStatusPanel.class])
            return panel;
    }
    return nil;
}

- (void) show {
    [self.summaryTextField sizeToFit];
    [self.detailTextField sizeToFit];
    self.contentView.needsLayout = YES;
    [self.contentView layoutSubtreeIfNeeded];
    self.contentView.layer.borderColor = [NSColor blueColor].CGColor;
    self.contentView.layer.borderWidth = 1.0;
    NSRect r = NSInsetRect(self.contentView.frame, -24.0, -24.0);
    r = BNCCenterRectOverPoint(r, self.arrowPoint);
    r.origin.y = self.arrowPoint.y - r.size.height;
    [self setFrame:r display:YES animate:NO];
    [self makeKeyAndOrderFront:self];
    [self setIsVisible:YES];
    [self update];
    self.selfReference = self;
    self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventTypeLeftMouseDown|NSEventTypeRightMouseDown
        handler:^ NSEvent * _Nullable (NSEvent*event) {
            NSPoint point = event.locationInWindow;
            if (event.window) point = [event.window convertPointToScreen:point];
            if (!NSPointInRect(point, self.frame))
                [self dismiss];
            return event;
        }
    ];
}

- (void) dismiss {
    if (self.eventMonitor) [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor = nil;
    [self setIsVisible:NO];
    [self close];
    [self orderOut:self];
    self.selfReference = nil;
}

@end
