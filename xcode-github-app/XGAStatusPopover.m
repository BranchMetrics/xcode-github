/**
 @file          XGAStatusPopover.m
 @package       xcode-github-app
 @brief         A status popover for the status and log windows.

 @author        Edward Smith
 @date          July 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGAStatusPopover.h"

@interface XGALabel : NSTextField
@end

@implementation XGALabel

- (NSSize) intrinsicContentSize {
    return (self.stringValue.length > 0) ? [super intrinsicContentSize] : NSMakeSize(0.0, 0.0);
}

@end

#pragma mark - XGAStatusPopover

@interface XGAStatusPopover ()
@property (strong) IBOutlet NSPopover*popover;
@end

@implementation XGAStatusPopover

- (instancetype) init {
    self = [super initWithNibName:nil bundle:nil];
    [self loadView];
    self.titleTextField.stringValue = @"";
    self.statusTextField.stringValue = @"";
    self.detailTextField.stringValue = @"";
    return self;
}

- (void) close {
    [self.popover close];
}

- (void) showRelativeToRect:(NSRect)positioningRect
                     ofView:(NSView *)positioningView
              preferredEdge:(NSRectEdge)preferredEdge {
    [self.popover showRelativeToRect:positioningRect
        ofView:positioningView
        preferredEdge:preferredEdge];
}

@end
