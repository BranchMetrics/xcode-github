/**
 @file          APPArrowPanel.m
 @package       xcode-github-app
 @brief         A heads-up panel that draws an indicator arrow at the indicated place.

 @author        Edward Smith
 @date          July 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "APPArrowPanel.h"
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

#pragma mark - APPArrowPanel

@interface APPArrowPanel ()
@property (strong) APPArrowPanel*selfReference;
@property (strong) id eventMonitor;
@end

@implementation APPArrowPanel

- (instancetype)initWithContentRect:(NSRect)contentRect
        styleMask:(NSWindowStyleMask)style
        backing:(NSBackingStoreType)backingStoreType
        defer:(BOOL)flag {
    style = NSWindowStyleMaskBorderless | NSWindowStyleMaskUtilityWindow;
    self = [super initWithContentRect:contentRect styleMask:style backing:backingStoreType defer:flag];
    if (!self) return self;
    self.backgroundColor = [NSColor clearColor];
    self.hasShadow = NO;
    self.opaque = NO;
    return self;
}

+ (instancetype) loadPanel {
    Class c = self.class;
    NSArray*objects = nil;
    [[NSBundle mainBundle]
        loadNibNamed:NSStringFromClass(c)
        owner:nil
        topLevelObjects:&objects];
    for (id panel in objects) {
        if ([panel isKindOfClass:self])
            return panel;
    }
    return nil;
}

- (void) show {
    self.contentView.layer.backgroundColor =
        [NSColor colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.85].CGColor;
    self.contentView.layer.cornerRadius = 3.0;
    self.contentView.needsLayout = YES;
    [self.contentView layoutSubtreeIfNeeded];
    NSRect r = NSInsetRect(self.contentView.frame, -24.0, -24.0);
//  r.size.width = 600.0;
    r = BNCCenterRectOverPoint(r, self.arrowPoint);
    r.origin.y = self.arrowPoint.y - r.size.height;
    [self setFrame:r display:YES animate:NO];
    [self setIsVisible:YES];
    [self makeKeyAndOrderFront:self];
    [self update];
    self.selfReference = self;
    if (self.eventMonitor) [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor =
        [NSEvent addLocalMonitorForEventsMatchingMask:NSEventTypeLeftMouseDown|NSEventTypeRightMouseDown
            handler:^ NSEvent * _Nullable (NSEvent*event) {
                NSPoint point = event.locationInWindow;
                if (event.window) point = [event.window convertPointToScreen:point];
                if (!NSPointInRect(point, self.frame))
                    [self dismiss];
                return event;
            }
        ];
}

- (void) dealloc {
    if (self.eventMonitor) [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor = nil;
}

- (void) dismiss {
    if (self.eventMonitor) [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor = nil;
    [self setIsVisible:NO];
    [self orderOut:self];
    self.selfReference = nil;
}

- (void) close {
    if (self.eventMonitor) [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor = nil;
    self.selfReference = nil;
    [super close];
}

- (BOOL) isShowing {
    return self.isVisible;
}

@end
