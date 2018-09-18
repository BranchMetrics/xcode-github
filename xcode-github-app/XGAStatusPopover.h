/**
 @file          XGAStatusPopover.h
 @package       xcode-github-app
 @brief         A status popover for the status and log windows.

 @author        Edward Smith
 @date          July 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface XGAStatusPopover : NSViewController
@property (strong) IBOutlet NSTextField*titleTextField;
@property (strong) IBOutlet NSImageView*statusImageView;
@property (strong) IBOutlet NSTextField*statusTextField;
@property (strong) IBOutlet NSTextField*detailTextField;

- (void) close;
- (void) showRelativeToRect:(NSRect)positioningRect
                     ofView:(NSView *)positioningView
              preferredEdge:(NSRectEdge)preferredEdge;

@end

NS_ASSUME_NONNULL_END
