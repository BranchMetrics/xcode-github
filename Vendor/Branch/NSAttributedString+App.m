/**
 @file          NSAttributedString+App.m
 @package       xcode-github-app
 @brief         Category methods for working with attributed strings.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "NSAttributedString+App.h"

@implementation NSAttributedString (App)

+ (NSAttributedString*) stringWithImage:(NSImage*)image rect:(NSRect)rect {
    NSData*imageData = [image TIFFRepresentation];
    if (!imageData) return [[NSAttributedString alloc] init];
    
    NSTextAttachment*a =
        [[NSTextAttachment alloc]
            initWithData:imageData
            ofType:(__bridge NSString*)kUTTypeTIFF];
    a.image = image;
    if (NSEqualRects(rect, NSZeroRect))
        rect = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    a.bounds = rect;
    NSAttributedString *string = [NSAttributedString attributedStringWithAttachment:a];
    return string;
}

+ (NSMutableAttributedString*) stringWithStrings:(NSAttributedString*)string, ... {
    va_list list;
    va_start(list, string);

    NSMutableAttributedString *result = [NSMutableAttributedString new];
    while (string) {
        if ([string isKindOfClass:NSString.class])
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:(NSString*)string]];
        else
        if ([string isKindOfClass:NSAttributedString.class])
            [result appendAttributedString:string];
        string = va_arg(list, NSAttributedString*);
    }

    va_end(list);
    return result;
}

+ (NSAttributedString*) stringWithFormat:(NSString *)format, ... {
    va_list argList;
    va_start(argList, format);
    NSString*s = [[NSString alloc] initWithFormat:format arguments:argList];
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:s];
    va_end(argList);
    return as;
}

@end
