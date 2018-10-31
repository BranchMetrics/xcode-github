/**
 @file          APFormattedString.h
 @package       xcode-github
 @brief         A generalized formatted string that can render multiple formats.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface APFormattedString : NSObject

+ (instancetype) plainText:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
+ (instancetype) boldText:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
+ (instancetype) italicText:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
+ (instancetype) line;

- (instancetype) plainText:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (instancetype) boldText:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (instancetype) italicText:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (instancetype) line;

- (instancetype) append:(APFormattedString*)string;

- (NSString*) renderText;
- (NSString*) renderMarkDown;

#if TARGET_OS_IOS
- (NSAttributedString*) renderAttributedStringWithFont:(UIFont*)font;
#elif TARGET_OS_OSX
- (NSAttributedString*) renderAttributedStringWithFont:(NSFont*)font;
#endif

@end

@interface NSString (APFormattedString)
- (NSRange) rangeOfAlphanumericSubstring;
@end

NS_ASSUME_NONNULL_END
