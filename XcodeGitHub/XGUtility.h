/**
 @file          XGUtility.h
 @package       xcode-github
 @brief         Small utility functions and classes.

 @author        Edward Smith
 @date          November 1, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDateFormatter (xcodegithub)
+ (NSDateFormatter*_Nonnull) dateFormatter8601;
@end

FOUNDATION_EXPORT NSString* XGDurationStringFromTimeInterval(NSTimeInterval timeInterval);

NS_ASSUME_NONNULL_END
