/**
 @file          APFormattedString.m
 @package       xcode-github
 @brief         A generalized formatted string that can render multiple formats.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "APFormattedString.h"
#import <CoreText/CoreText.h>

#pragma mark APFormattedString

@interface APFormattedString ()
@property (strong) NSMutableArray<APFormattedStringBuilder*>*builderArray;
@end

#pragma mark - APFormattedStringBuilder

@interface APFormattedStringBuilder ()
@property (strong) APFormattedString*formattedString;
@end

@implementation APFormattedStringBuilder

- (instancetype) initWithFormattedString:(APFormattedString*)formattedString {
    self = [super init];
    if (!self) return self;
    self.formattedString = formattedString;
    return self;
}

#define createBuilder \
    va_list argList; \
    va_start(argList, format); \
    APFormattedStringBuilder* builder = [[APFormattedStringBuilder alloc] init]; \
    builder.string = [[NSString alloc] initWithFormat:format arguments:argList]; \
    [self.formattedString.builderArray addObject:builder]; \
    va_end(argList);

- (instancetype) appendPlain:(NSString*)format, ... {
    createBuilder;
    builder.style = APFormattedStringFormatPlain;
    return self;
}

- (instancetype) appendBold:(NSString*)format, ... {
    createBuilder;
    builder.style = APFormattedStringFormatBold;
    return self;
}

- (instancetype) appendItalic:(NSString*)format, ... {
    createBuilder;
    builder.style = APFormattedStringFormatItalic;
    return self;
}

- (instancetype) appendLine {
    APFormattedStringBuilder* builder = [[APFormattedStringBuilder alloc] init];
    builder.style = APFormattedStringFormatLine;
    builder.string = @"\n";
    [self.formattedString.builderArray addObject:builder];
    return self;
}

- (APFormattedString*) build {
    return self.formattedString;
}

@end

#pragma mark - APFormattedString

@implementation APFormattedString

+ (APFormattedStringBuilder*) builder {
    APFormattedString* formattedString = [[APFormattedString alloc] init];
    return [formattedString builder];
}

- (APFormattedStringBuilder*) builder {
    if (!self.builderArray) self.builderArray = [NSMutableArray new];
    APFormattedStringBuilder*builder =
        [[APFormattedStringBuilder alloc] initWithFormattedString:self];
    return builder;
}

+ (APFormattedString*) plainText:(NSString*)text {
   return [[[APFormattedString builder] appendPlain:@"%@", text] build];
}

- (NSString*) renderText {
    NSMutableString*string = [NSMutableString new];
    for (APFormattedStringBuilder*builder in self.builderArray) {
        [string appendString:builder.string];
    }
    return string;
}

- (NSString*) renderMarkDown {
    NSMutableString*string = [NSMutableString new];
    for (APFormattedStringBuilder*builder in self.builderArray) {
        switch (builder.style) {
        default:
        case APFormattedStringFormatPlain:
            [string appendString:builder.string];
            break;
        case APFormattedStringFormatBold:
            [string appendFormat:@"**%@**", builder.string];
            break;
        case APFormattedStringFormatItalic:
            [string appendFormat:@"*%@*", builder.string];
            break;
        case APFormattedStringFormatLine:
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
    for (APFormattedStringBuilder*builder in self.builderArray) {
        NSDictionary*attributes = @{};
        switch (builder.style) {
        default:
        case APFormattedStringFormatPlain:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: font,
            };
            break;
        case APFormattedStringFormatBold:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: boldFont,
            };
            break;
        case APFormattedStringFormatItalic:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: italicFont,
            };
            break;
        case APFormattedStringFormatLine:
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
    for (APFormattedStringBuilder*builder in self.builderArray) {
        NSDictionary*attributes = @{};
        switch (builder.style) {
        default:
        case APFormattedStringFormatPlain:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: font,
            };
            break;
        case APFormattedStringFormatBold:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: boldFont,
            };
            break;
        case APFormattedStringFormatItalic:
            attributes = @{
                (__bridge NSString*) kCTFontAttributeName: italicFont,
            };
            break;
        case APFormattedStringFormatLine:
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
