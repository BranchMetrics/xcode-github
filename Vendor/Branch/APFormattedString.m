/**
 @file          APPFormattedString.m
 @package       xcode-github
 @brief         A generalized formatted string that can render multiple formats.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "APFormattedString.h"
#import <CoreText/CoreText.h>

@implementation NSString (APFormattedString)

- (NSRange) rangeOfAlphanumericSubstring {
    if (self.length == 0) return NSMakeRange(NSNotFound, 0);
    NSCharacterSet*characterSet = [NSCharacterSet alphanumericCharacterSet];

    NSRange alpha = [self rangeOfCharacterFromSet:characterSet
        options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
    if (alpha.location == NSNotFound) return NSMakeRange(NSNotFound, 0);

    NSRange omega = [self rangeOfCharacterFromSet:characterSet
        options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSBackwardsSearch];

    NSRange range = NSMakeRange(alpha.location, omega.location - alpha.location + 1);
    return range;
}

@end

#pragma mark -

typedef NS_ENUM(NSInteger, APPFormattedStringStyle) {
    APPFormattedStringFormatPlain,
    APPFormattedStringFormatBold,
    APPFormattedStringFormatItalic,
    APPFormattedStringFormatLine,
};

#pragma mark APPFormattedStringPart

@interface APPFormattedStringPart : NSObject
@property (assign) APPFormattedStringStyle style;
@property (strong) NSString*_Nonnull string;
@end

@implementation APPFormattedStringPart
@end

#pragma mark - APPFormattedString

@interface APFormattedString ()
@property (strong) NSMutableArray<APPFormattedStringPart*>*partArray;
@end

@implementation APFormattedString

- (instancetype) init {
    self = [super init];
    if (!self) return self;
    self.partArray = [NSMutableArray new];
    return self;
}

#define createPart \
    va_list argList; \
    va_start(argList, format); \
    __auto_type part = [[APPFormattedStringPart alloc] init]; \
    part.string = [[NSString alloc] initWithFormat:format arguments:argList]; \
    [self.partArray addObject:part]; \
    va_end(argList);

- (instancetype) plainText:(NSString*)format, ... {
    createPart;
    part.style = APPFormattedStringFormatPlain;
    return self;
}

- (instancetype) boldText:(NSString*)format, ... {
    createPart;
    part.style = APPFormattedStringFormatBold;
    return self;
}

- (instancetype) italicText:(NSString*)format, ... {
    createPart;
    part.style = APPFormattedStringFormatItalic;
    return self;
}

- (instancetype) line {
    __auto_type part = [[APPFormattedStringPart alloc] init];
    part.style = APPFormattedStringFormatLine;
    part.string = @"\n";
    [self.partArray addObject:part];
    return self;
}

- (instancetype) append:(APFormattedString *)string {
    [self.partArray addObjectsFromArray:string.partArray];
    return self;
}

#define createFormattedString \
    va_list argList; \
    va_start(argList, format); \
    __auto_type formattedString = [APFormattedString new]; \
    __auto_type part = [[APPFormattedStringPart alloc] init]; \
    part.string = [[NSString alloc] initWithFormat:format arguments:argList]; \
    [formattedString.partArray addObject:part]; \
    va_end(argList);

+ (instancetype) plainText:(NSString*)format, ... {
    createFormattedString;
    part.style = APPFormattedStringFormatPlain;
    return formattedString;
}

+ (instancetype) boldText:(NSString*)format, ... {
    createFormattedString;
    part.style = APPFormattedStringFormatBold;
    return formattedString;
}

+ (instancetype) italicText:(NSString*)format, ... {
    createFormattedString;
    part.style = APPFormattedStringFormatItalic;
    return formattedString;
}

+ (instancetype) line {
    return [[APFormattedString new] line];
}

- (NSString*) renderText {
    NSMutableString*string = [NSMutableString new];
    for (APPFormattedStringPart*part in self.partArray) {
        [string appendString:part.string];
    }
    return string;
}

- (NSString*) renderMarkDown {
    NSMutableString*string = [NSMutableString new];
    for (APPFormattedStringPart*part in self.partArray) {
        NSRange r;
        switch (part.style) {
        default:
        case APPFormattedStringFormatPlain:
            [string appendString:part.string];
            break;
        case APPFormattedStringFormatBold:
            r = [part.string rangeOfAlphanumericSubstring];
            if (r.location == NSNotFound)
                [string appendString:part.string];
            else {
                [string appendString:[part.string substringToIndex:r.location]];
                [string appendString:@"**"];
                [string appendString:[part.string substringWithRange:r]];
                [string appendString:@"**"];
                [string appendString:[part.string substringFromIndex:r.location+r.length]];
            }
            break;
        case APPFormattedStringFormatItalic:
            r = [part.string rangeOfAlphanumericSubstring];
            if (r.location == NSNotFound)
                [string appendString:part.string];
            else {
                [string appendString:[part.string substringToIndex:r.location]];
                [string appendString:@"_"];
                [string appendString:[part.string substringWithRange:r]];
                [string appendString:@"_"];
                [string appendString:[part.string substringFromIndex:r.location+r.length]];
            }
            break;
            break;
        case APPFormattedStringFormatLine:
            [string appendString:@"\n---\n"];
            break;
        }
    }
    return string;
}

#if TARGET_OS_IOS

- (NSAttributedString*) renderAttributedStringWithFont:(UIFont*)font {
    UIFontDescriptor *descriptor =
        [[font fontDescriptor]
            fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFont*boldFont = [UIFont fontWithDescriptor:descriptor size:0.0];

    descriptor =
        [[font fontDescriptor]
            fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    UIFont*italicFont = [UIFont fontWithDescriptor:descriptor size:0.0];

    NSMutableAttributedString*string = [NSMutableAttributedString new];
    for (APPFormattedStringPart*part in self.partArray) {
        NSDictionary*attributes = @{};
        switch (part.style) {
        default:
        case APPFormattedStringFormatPlain:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: font,
            };
            break;
        case APPFormattedStringFormatBold:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: boldFont,
            };
            break;
        case APPFormattedStringFormatItalic:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: italicFont,
            };
            break;
        case APPFormattedStringFormatLine:
            break;
        }
        NSAttributedString*as =
            [[NSAttributedString alloc] initWithString:part.string attributes:attributes];
        [string appendAttributedString:as];
    }
    return string;
}

#elif TARGET_OS_OSX

- (NSAttributedString*) renderAttributedStringWithFont:(NSFont*)font {
    NSFontDescriptor *descriptor =
        [[font fontDescriptor]
            fontDescriptorWithSymbolicTraits:NSFontDescriptorTraitBold];
    NSFont*boldFont = [NSFont fontWithDescriptor:descriptor size:0.0];

    descriptor =
        [[font fontDescriptor]
            fontDescriptorWithSymbolicTraits:NSFontDescriptorTraitItalic];
    NSFont*italicFont = [NSFont fontWithDescriptor:descriptor size:0.0];

    NSMutableAttributedString*string = [NSMutableAttributedString new];
    for (APPFormattedStringPart*part in self.partArray) {
        NSDictionary*attributes = @{};
        switch (part.style) {
        default:
        case APPFormattedStringFormatPlain:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: font,
            };
            break;
        case APPFormattedStringFormatBold:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: boldFont,
            };
            break;
        case APPFormattedStringFormatItalic:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: italicFont,
            };
            break;
        case APPFormattedStringFormatLine:
            break;
        }
        NSAttributedString*as =
            [[NSAttributedString alloc] initWithString:part.string attributes:attributes];
        [string appendAttributedString:as];
    }
    return string;
}

#endif

- (NSString*) description {
    return [self renderText];
}

@end
