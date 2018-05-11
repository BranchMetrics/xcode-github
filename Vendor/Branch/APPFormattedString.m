/**
 @file          APPFormattedString.m
 @package       xcode-github
 @brief         A generalized formatted string that can render multiple formats.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "APPFormattedString.h"
#import <CoreText/CoreText.h>

#pragma mark APPFormattedString

@interface APPFormattedString ()
@property (strong) NSMutableArray<APPFormattedStringBuilder*>*builderArray;
@end

#pragma mark - APPFormattedStringBuilder

@interface APPFormattedStringBuilder ()
@property (strong) APPFormattedString*formattedString;
@end

@implementation APPFormattedStringBuilder

- (instancetype) initWithFormattedString:(APPFormattedString*)formattedString {
    self = [super init];
    if (!self) return self;
    self.formattedString = formattedString;
    return self;
}

#define createBuilder \
    va_list argList; \
    va_start(argList, format); \
    APPFormattedStringBuilder* builder = [[APPFormattedStringBuilder alloc] init]; \
    builder.string = [[NSString alloc] initWithFormat:format arguments:argList]; \
    [self.formattedString.builderArray addObject:builder]; \
    va_end(argList);

- (instancetype) appendPlain:(NSString*)format, ... {
    createBuilder;
    builder.style = APPFormattedStringFormatPlain;
    return self;
}

- (instancetype) appendBold:(NSString*)format, ... {
    createBuilder;
    builder.style = APPFormattedStringFormatBold;
    return self;
}

- (instancetype) appendItalic:(NSString*)format, ... {
    createBuilder;
    builder.style = APPFormattedStringFormatItalic;
    return self;
}

- (instancetype) appendLine {
    APPFormattedStringBuilder* builder = [[APPFormattedStringBuilder alloc] init];
    builder.style = APPFormattedStringFormatLine;
    builder.string = @"\n";
    [self.formattedString.builderArray addObject:builder];
    return self;
}

- (APPFormattedString*) build {
    return self.formattedString;
}

@end

#pragma mark - APPFormattedString

@implementation APPFormattedString

+ (APPFormattedStringBuilder*) builder {
    APPFormattedString* formattedString = [[APPFormattedString alloc] init];
    return [formattedString builder];
}

- (APPFormattedStringBuilder*) builder {
    if (!self.builderArray) self.builderArray = [NSMutableArray new];
    APPFormattedStringBuilder*builder =
        [[APPFormattedStringBuilder alloc] initWithFormattedString:self];
    return builder;
}

+ (APPFormattedString*) plainText:(NSString*)text {
   return [[[APPFormattedString builder] appendPlain:@"%@", text] build];
}

- (NSString*) renderText {
    NSMutableString*string = [NSMutableString new];
    for (APPFormattedStringBuilder*builder in self.builderArray) {
        [string appendString:builder.string];
    }
    return string;
}

- (NSString*) renderMarkDown {
    NSMutableString*string = [NSMutableString new];
    for (APPFormattedStringBuilder*builder in self.builderArray) {
        switch (builder.style) {
        default:
        case APPFormattedStringFormatPlain:
            [string appendString:builder.string];
            break;
        case APPFormattedStringFormatBold:
            [string appendFormat:@"**%@**", builder.string];
            break;
        case APPFormattedStringFormatItalic:
            [string appendFormat:@"*%@*", builder.string];
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
    for (APPFormattedStringBuilder*builder in self.builderArray) {
        NSDictionary*attributes = @{};
        switch (builder.style) {
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
            [[NSAttributedString alloc] initWithString:builder.string attributes:attributes];
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
    for (APPFormattedStringBuilder*builder in self.builderArray) {
        NSDictionary*attributes = @{};
        switch (builder.style) {
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
            [[NSAttributedString alloc] initWithString:builder.string attributes:attributes];
        [string appendAttributedString:as];
    }
    return string;
}

#endif

@end
