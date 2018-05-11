/**
 @file          APPFormattedString.h
 @package       xcode-github
 @brief         A generalized formatted string that can render multiple formats.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#if TARGET_OS_IOS
    #if __has_feature(modules)
    @import UIKit;
    #else
    #import <UIKit/UIKit.h>
    #endif
    typedef UIFont APFont;
#elif TARGET_OS_OSX
    #if __has_feature(modules)
    @import AppKit;
    #else
    #import <AppKit/AppKit.h>
    #endif
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, APPFormattedStringStyle) {
    APPFormattedStringFormatPlain,
    APPFormattedStringFormatBold,
    APPFormattedStringFormatItalic,
    APPFormattedStringFormatLine,
};

@class APPFormattedString;

#pragma mark - APPFormattedStringBuilder

@interface APPFormattedStringBuilder : NSObject
@property (assign) APPFormattedStringStyle style;
@property (strong) NSString*_Nonnull string;

- (instancetype) appendPlain:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (instancetype) appendBold:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (instancetype) appendItalic:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (instancetype) appendLine;

- (APPFormattedString*) build;
@end

#pragma mark - APPFormattedString

@interface APPFormattedString : NSObject

+ (APPFormattedStringBuilder*) builder;
- (APPFormattedStringBuilder*) builder;

+ (APPFormattedString*) plainText:(NSString*)text;

- (NSString*) renderText;
- (NSString*) renderMarkDown;

#if TARGET_OS_IOS
- (NSAttributedString*) renderAttributedStringWithFont:(UIFont*)font;
#elif TARGET_OS_OSX
- (NSAttributedString*) renderAttributedStringWithFont:(NSFont*)font;
#endif

@end

NS_ASSUME_NONNULL_END
