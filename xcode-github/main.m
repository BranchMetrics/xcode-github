/**
 @file          main.m
 @package       xcode-github
 @brief         Command line interface for the xcode-github app.

 @author        Edward Smith
 @date          February 28, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "XGCommandOptions.h"
#import "XGCommand.h"
#import "BNCLog.h"
#include <sysexits.h>

static BNCLogLevel global_logLevel = BNCLogLevelWarning;

void LogOutputFunction(
        NSDate*_Nonnull timestamp,
        BNCLogLevel level,
        NSString *_Nullable message
    ) {
    if (level < global_logLevel || !message) return;
    NSRange range = [message rangeOfString:@") "];
    if (range.location != NSNotFound) {
        message = [message substringFromIndex:range.location+2];
    }
    NSData *data = [message dataUsingEncoding:NSNEXTSTEPStringEncoding];
    if (!data) return;
    int descriptor = (level == BNCLogLevelLog) ? STDOUT_FILENO : STDERR_FILENO;
    write(descriptor, data.bytes, data.length);
    write(descriptor, "\n   ", sizeof('\n'));
}

int main(int argc, char*const argv[]) {
    int returnCode = EXIT_FAILURE;
    BOOL repeatForever = NO;

start:
    @autoreleasepool {
        BNCLogSetOutputFunction(LogOutputFunction);
        BNCLogSetDisplayLevel(BNCLogLevelWarning);

        // XGCommandOptions *options = [XGCommandOptions testWithBranchSDK];
        XGCommandOptions *options = [XGCommandOptions testWithXcodeGitHub];
        // XGCommandLineOptions *options = [XGCommandLineOptions testWithBranchLabs];
        // XGCommandLineOptions *options = [[XGCommandLineOptions alloc] initWithArgc:argc argv:argv];
        if (options.badOptionsError) {
            returnCode = EX_USAGE;
            goto exit;
        }

        if (options.showHelp) {
            NSData *data = [[XGCommandOptions helpString] dataUsingEncoding:NSUTF8StringEncoding];
            write(STDOUT_FILENO, data.bytes, data.length);
            returnCode = EXIT_SUCCESS;
            goto exit;
        }
        global_logLevel = MIN(MAX(BNCLogLevelWarning - options.verbosity, BNCLogLevelAll), BNCLogLevelNone);
        BNCLogSetDisplayLevel(global_logLevel);
        
        if (options.showVersion) {
            BNCLog(@"xcode-github version %@(%@).",
                [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
            );
            returnCode = EXIT_SUCCESS;
            goto exit;
        }

        if (options.showStatusOnly) {
            if (XGShowXcodeBotStatus(options.xcodeServerName) == nil)
                returnCode = EXIT_SUCCESS;
            goto exit;
        }

        NSError *error = XGUpdateXcodeBotsWithGitHub(options);
        if (error) {
            returnCode = [error.userInfo[@"return_code"] intValue];
            goto exit;
        }

        error = XGShowXcodeBotStatus(options.xcodeServerName);
        if (error == nil) returnCode = EXIT_SUCCESS;

        repeatForever = options.repeatForever;
    }

    if (repeatForever) {
        sleep(60);
        goto start;
    }

exit:
    BNCLogFlushMessages();
    return returnCode;
}
