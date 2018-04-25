/**
 @file          main.m
 @package       xcode-github
 @brief         Main body of the xcode-github app.

 @author        Edward Smith
 @date          February 28, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

@import Foundation;
#import "XGXcodeBot.h"
#import "XGGitHubPullRequest.h"
#import "XGCommandOptions.h"
#import "BNCLog.h"
#import "BNCNetworkService.h"
#import "XGCommand.h"
#include <sysexits.h>

NSString *helpString =
@"xcode-github - Creates an Xcode test bots for new GitHub PRs.\n"
 "\n"
 "usage: xcode-github [-dhsVv] -g <github-auth-token>\n"
 "                 -t <bot-template> -x <xcode-server-domain-name>\n"
 "\n"
 "\n"
 "  -d, --dryrun\n"
 "      Dry run. Print what would be done.\n"
 "\n"
 "  -g, --github <github-auth-token>\n"
 "      A GitHub auth token that allows checking the status of a repo\n"
 "      and change a PR's status.\n"
 "\n"
 "  -h, --help\n"
 "      Print this help information.\n"
 "\n"
 "  -s, --status\n"
 "      Only print the status of the xcode server bots and quit.\n"
 "\n"
 "  -t --template <bot-template>\n"
 "      An existing bot on the xcode server that is used as a template\n"
 "      for the new GitHub PR bots.\n"
 "\n"
 "  -V, --version\n"
 "      Show version and exit.\n"
 "\n"
 "  -v, --verbose\n"
 "      Verbose. Extra 'v' increases the verbosity.\n"
 "\n"
 "  -x, --xcodeserver <xcode-server-domain-name>\n"
 "      The network name of the xcode server.\n"
 "\n"
 ;

NSError *showBotStatus(NSString* xcodeServerName) {
    // Update the bots and display the results:

    BNCLogInfo(@"Refreshing Xcode bot status...");
    NSError *error = nil;
    NSDictionary<NSString*, XGXcodeBot*> *bots =
        [XGXcodeBot botsForServer:xcodeServerName error:&error];
    if (error) {
        BNCLogError(@"Can't retrieve Xcode bot information from '%@': %@.",
            xcodeServerName, error);
        return error;
    }

    if (bots.count == 0) {
        BNCLog(@"Xcode bot status: No Xcode bots.");
    } else {
        BNCLog(@"Xcode bot status:");
        for (XGXcodeBot *bot in bots.objectEnumerator) {
            XGXcodeBotStatus *status = [bot status];
            BNCLog(@"%@", status);
        }
    }
    return nil;
}

int main(int argc, char*const argv[]) {
    int returnCode = EXIT_FAILURE;
    @autoreleasepool {
        BNCLogSetDisplayLevel(BNCLogLevelWarning);
        // XGCommandLineOptions *options = [XGCommandLineOptions testWithBranchLabs];
        XGCommandOptions *options = [XGCommandOptions testWithBranchSDK];
        // XGCommandLineOptions *options = [[XGCommandLineOptions alloc] initWithArgc:argc argv:argv];
        if (options.badOptionsError) {
            returnCode = EX_USAGE;
            goto exit;
        }

        if (options.showHelp) {
            NSData *data = [helpString dataUsingEncoding:NSUTF8StringEncoding];
            write(STDOUT_FILENO, data.bytes, data.length);
            returnCode = EXIT_SUCCESS;
            goto exit;
        }
        BNCLogLevel logLevel = MIN(MAX(BNCLogLevelWarning - options.verbosity, BNCLogLevelAll), BNCLogLevelNone);
        BNCLogSetDisplayLevel(logLevel);
        
        if (options.showVersion) {
            BNCLog(@"xcode-github version %@(%@).",
                [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
            );
            returnCode = EXIT_SUCCESS;
            goto exit;
        }

        // Allow self-signed certs from the xcode server:
        [[BNCNetworkService shared].anySSLCertHosts addObject:options.xcodeServerName];

        if (options.showStatusOnly) {
            if (showBotStatus(options.xcodeServerName) == nil)
                returnCode = EXIT_SUCCESS;
            goto exit;
        }

        NSError *error = XGUpdateXcodeBotsWithGitHub(options);
        if (error) {
            returnCode = [error.userInfo[@"return_code"] intValue];
            goto exit;
        }

        error = showBotStatus(options.xcodeServerName);
        if (error == nil) returnCode = EXIT_SUCCESS;
    }
    
exit:
    BNCLogFlushMessages();
    return returnCode;
}
