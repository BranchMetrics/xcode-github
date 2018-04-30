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

typedef NS_ENUM(NSInteger, APFormattedStringStyle) {
    APFormattedStringFormatPlain,
    APFormattedStringFormatBold,
    APFormattedStringFormatItalic,
    APFormattedStringFormatLine,
};

@class APFormattedString;

#pragma mark - APFormattedStringBuilder

@interface APFormattedStringBuilder : NSObject
@property (assign) APFormattedStringStyle style;
@property (strong) NSString*_Nonnull string;

- (instancetype) appendPlain:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (instancetype) appendBold:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (instancetype) appendItalic:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
- (instancetype) appendLine;

- (APFormattedString*) build;
@end

#pragma mark - APFormattedString

@interface APFormattedString : NSObject

+ (APFormattedStringBuilder*) builder;
- (APFormattedStringBuilder*) builder;

+ (APFormattedString*) plainText:(NSString*)text;

- (NSString*) renderText;
- (NSString*) renderMarkDown;
- (NSAttributedString*) renderAttributedStringWithFont:(NSFont*)font;

@end

NS_ASSUME_NONNULL_END
