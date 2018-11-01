/**
 @file          XGUtility.m
 @package       xcode-github
 @brief         Small utility functions and classes.

 @author        Edward Smith
 @date          November 1, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGUtility.h"

@implementation NSDateFormatter (xcodegithub)

+ (NSDateFormatter*) dateFormatter8601 {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSX";
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    return formatter;
}

@end

#pragma mark - XGDurationStringFromTimeInterval

NSString* XGDurationStringFromTimeInterval(NSTimeInterval timeInterval) {
    int seconds = (int) round(fabs(timeInterval));
    int minutes = seconds / 60;
    seconds = seconds % 60;
    int hours = minutes / 60;
    minutes = minutes % 60;

    NSMutableString *string = [NSMutableString new];
    if (hours == 1)
        [string appendString:@"one hour, "];
    else
    if (hours > 0)
        [string appendFormat:@"%d hours, ", hours];

    if (minutes == 1)
        [string appendString:@"one minute, "];
    else
    if (minutes > 0)
        [string appendFormat:@"%d minutes, ", minutes];

    if (seconds == 1)
        [string appendString:@"one second, "];
    else
    if (seconds > 0)
        [string appendFormat:@"%d seconds, ", seconds];

    if (string.length > 2)
        [string deleteCharactersInRange:NSMakeRange(string.length-2, 2)];
    else
        string = [NSMutableString stringWithString:@"zero seconds"];

    NSString *result = [NSString stringWithFormat:@"%@%@",
        [[string substringToIndex:1] uppercaseString],
        [string substringFromIndex:1]];

    return result;
}
