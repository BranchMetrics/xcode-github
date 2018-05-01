//
//  XGCommand.m
//  xcode-github
//
//  Created by Edward on 4/24/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGCommand.h"
#import "BNCLog.h"
#import "XGXcodeBot.h"
#import "XGGitHubPullRequest.h"
#include <sysexits.h>

#pragma mark Settings

NSMutableDictionary*_Nonnull XGMutableDictionaryWithDictionary(NSDictionary*_Nullable dictionary) {
    if ([dictionary isKindOfClass:NSMutableDictionary.class])
        return (NSMutableDictionary*) dictionary;
    else
    if ([dictionary isKindOfClass:NSDictionary.class])
        return [NSMutableDictionary dictionaryWithDictionary:dictionary];
    else
        return [NSMutableDictionary new];
}

/**
    NSUserDefaults.standardUserDefaults.githubStatus

    dictionary[repoOwner][repoName][branch][sha] = statusString
*/
NSMutableDictionary*_Nonnull XGGitHubStatusDictionaryWithPR(XGGitHubPullRequest*_Nonnull pr) {
    NSMutableDictionary*dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"githubStatus"];
    dictionary = XGMutableDictionaryWithDictionary(dictionary);
    dictionary[pr.repoOwner] =
        XGMutableDictionaryWithDictionary(dictionary[pr.repoOwner]);
    dictionary[pr.repoOwner][pr.repoName] =
        XGMutableDictionaryWithDictionary(dictionary[pr.repoOwner][pr.repoName]);
    dictionary[pr.repoOwner][pr.repoName][pr.branch] =
        XGMutableDictionaryWithDictionary(dictionary[pr.repoOwner][pr.repoName][pr.branch]);
    return dictionary;
}

void XGSetGitHubStatusDictionaryWithPR(XGGitHubPullRequest*_Nonnull pr, NSDictionary*_Nonnull dictionary) {
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:@"githubStatus"];
}

void XGDeleteGitHubStatusDictionaryWithBot(XGXcodeBot*_Nonnull bot) {
    NSMutableDictionary*dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"githubStatus"];
    dictionary = XGMutableDictionaryWithDictionary(dictionary);
    dictionary[bot.repoOwner] =
        XGMutableDictionaryWithDictionary(dictionary[bot.repoOwner]);
    dictionary[bot.repoOwner][bot.repoName] =
        XGMutableDictionaryWithDictionary(dictionary[bot.repoOwner][bot.repoName]);
    dictionary[bot.repoOwner][bot.repoName][bot.branch] = nil;
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:@"githubStatus"];
}

#pragma mark - Bot Functions

NSError*_Nullable XGCreateBotWithOptions(
        XGCommandOptions*_Nonnull options,
        XGGitHubPullRequest*_Nonnull pr,
        XGXcodeBot*_Nonnull templateBot,
        NSString*_Nonnull newBotName
    ) {
    if (options.dryRun) {
        BNCLog(@"Would create bot '%@'.", newBotName);
        return nil;
    }
    NSError *error = nil;
    BNCLogDebug(@"Creating bot '%@'...", newBotName);
    [pr setStatus:XGPullRequestStatusPending
        message:@"Creating Xcode bot..."
        statusURL:nil
        authToken:options.githubAuthToken];
    [XGXcodeBot duplicateBot:templateBot
        withNewName:newBotName
        gitHubBranchName:pr.branch
        error:&error];
    if (error) {
        BNCLogError(@"Can't create Xcode bot: %@.", error);
    }
    return error;
}

NSError*_Nullable XGDeleteBotWithOptions(
        XGCommandOptions*_Nonnull options,
        XGXcodeBot*_Nonnull bot
    ) {
    NSError*error = nil;
    if (options.dryRun) {
        BNCLog(@"Would delete bot '%@'.", bot.name);
        return error;
    }
    BNCLogDebug(@"Deleting old bot '%@'...", bot.name);
    error = [bot removeFromServer];
    if (error) {
        BNCLogError(
            @"Can't remove old bot named '%@' from server: %@.", bot.name, error
        );
        return error;
    }
    XGDeleteGitHubStatusDictionaryWithBot(bot);
    return error;
}

NSError*_Nullable XGUpdatePRStatus(
        XGCommandOptions*_Nonnull options,
        XGGitHubPullRequest*_Nonnull pr,
        XGXcodeBotStatus*_Nonnull botStatus
    ) {
    NSError*error = nil;
    XGPullRequestStatus status = XGPullRequestStatusError;

    /*
    XGXcodeBotStatus:

    XGPullRequestStatusError,
    XGPullRequestStatusFailure,
    XGPullRequestStatusPending,
    XGPullRequestStatusSuccess,
    */

    NSSet<NSString*>*failureResults = [NSSet setWithArray:@[
        @"build-errors",
        @"test-failures",
        @"build-failed",
        @"canceled",
    ]];
    NSSet<NSString*>*successResults = [NSSet setWithArray:@[
        @"succeeded",
        @"warnings",
        @"analyzer-warnings",
    ]];

    if ([botStatus.currentStep isEqualToString:@"completed"]) {
        if (botStatus.result == nil) {
        } else
        if ([successResults containsObject:botStatus.result]) {
            status = XGPullRequestStatusSuccess;
        } else
        if ([failureResults containsObject:botStatus.result]) {
            status = XGPullRequestStatusFailure;
        } else {
            status = XGPullRequestStatusError;
        }
    } else {
        status = XGPullRequestStatusPending;
    }

    NSString*message = botStatus.summaryString;

    if (options.dryRun) {
        BNCLog(@"Would update PR#%@ with status %@: %@.",
            pr.number, NSStringFromXGPullRequestStatus(status), message);
        return nil;
    }

    NSString*statusHash = [NSString stringWithFormat:@"%@:%@",
        NSStringFromXGPullRequestStatus(status), message];

    NSMutableDictionary*statusDictionary = XGGitHubStatusDictionaryWithPR(pr);
    NSString*lastStatusHash = statusDictionary[pr.repoOwner][pr.repoName][pr.branch][pr.sha];
    if ([lastStatusHash isEqualToString:statusHash])
        return nil;

    error = [pr setStatus:status
        message:(NSString*)message
        statusURL:nil
        authToken:options.githubAuthToken];
    if (error) return error;

    statusDictionary[pr.repoOwner][pr.repoName][pr.branch][pr.sha] = statusHash;
    XGSetGitHubStatusDictionaryWithPR(pr, statusDictionary);

    // Send a completion message:
    if ([botStatus.currentStep isEqualToString:@"completed"]) {
        error = [pr addComment:[botStatus.formattedDetailString renderMarkDown]
            authToken:options.githubAuthToken];
        if (error) return error;
    }

    return nil;
}

NSError*_Nullable XGUpdateXcodeBotsWithGitHub(XGCommandOptions*_Nonnull options) {
    NSError *error = nil;
    int returnCode = EXIT_FAILURE;
    {
        BNCLogDebug(@"Getting Xcode bots on '%@'...", options.xcodeServerName);

        NSDictionary<NSString*, XGXcodeBot*> *bots =
            [XGXcodeBot botsForServer:options.xcodeServerName error:&error];
        if (error) {
            BNCLogError(@"Can't retrieve Xcode bot information from %@: %@.",
                options.xcodeServerName, error);
            returnCode = EX_NOHOST;
            goto exit;
        }

        // Check that the template bot exists:
        XGXcodeBot *templateBot = bots[options.templateBotName];
        if (!templateBot) {
            BNCLogError(@"Can't find Xcode template bot named '%@'.", options.templateBotName);
            returnCode = EX_CONFIG;
            goto exit;
        }

        BNCLogDebug(@"Getting pull requests for '%@'...", templateBot.sourceControlRepository);

        NSDictionary<NSString*, XGGitHubPullRequest*> *pullRequests =
            [XGGitHubPullRequest pullsRequestsForRepository:templateBot.sourceControlRepository
                authToken:options.githubAuthToken
                error:&error];
        if (error) {
            BNCLogError(@"Can't retrieve pull requests from '%@': %@.",
            templateBot.sourceControlRepository, error);
            returnCode = EX_NOHOST;
            goto exit;
        }

        // Check for open pull requests with state 'open':
        for (XGGitHubPullRequest *pr in pullRequests.objectEnumerator) {
            NSString *newBotName = [XGXcodeBot botNameFromPRNumber:pr.number title:pr.title];
            XGXcodeBot *bot = bots[newBotName];
            if ([pr.state isEqualToString:@"open"]) {
                if (bot) {
                    error = XGUpdatePRStatus(options, pr, bot.status);
                } else {
                    error = XGCreateBotWithOptions(options, pr, templateBot, newBotName);
                }
                if (error) {
                    returnCode = EX_NOPERM;
                    goto exit;
                }
            }
        }

        // Check for bots with no PR and delete it:
        for (XGXcodeBot *bot in bots.objectEnumerator) {
            NSString *number = bot.pullRequestNumber;
            if (number && !pullRequests[number]) {
                error = XGDeleteBotWithOptions(options, bot);
                if (error) { returnCode = EX_NOPERM; goto exit; }
            }
        }

        error = nil;
        returnCode = EXIT_SUCCESS;
    }

exit:
    if (returnCode != EXIT_SUCCESS) {
        if (!error) error = [NSError errorWithDomain:NSMachErrorDomain code:KERN_FAILURE userInfo:nil];
        NSMutableDictionary *userInfo =
            ([error.userInfo isKindOfClass:NSDictionary.class])
            ? [error.userInfo mutableCopy]
            : [NSMutableDictionary new];
        userInfo[@"return_code"] = @(returnCode);
        error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
    }
    return error;
}
