/**
 @file          NSAttributedString+App.h
 @package       xcode-github-app
 @brief         Category methods for working with attributed strings.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (App)

+ (NSAttributedString*) stringWithImage:(NSImage*)image rect:(NSRect)rect;
+ (NSMutableAttributedString*) stringWithStrings:(NSAttributedString*)string, ... NS_REQUIRES_NIL_TERMINATION;
+ (NSAttributedString*) stringWithFormat:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);

@end

NS_ASSUME_NONNULL_END
