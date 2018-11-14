/**
 @file          XcodeGitHub.h
 @package       xcode-github
 @brief         XcodeGitHub umbrella header file.

 @author        Edward Smith
 @date          October 7, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XcodeGitHub.h"

FOUNDATION_EXPORT NSString*_Nonnull XGVersion() {
    NSDictionary*infoDictionary = [NSBundle bundleForClass:XGCommandOptions.class].infoDictionary;
    NSString*version = [NSString stringWithFormat:@"%@ (%@)",
        infoDictionary[@"CFBundleShortVersionString"],
        infoDictionary[@"CFBundleVersion"]];
    return version;
}
