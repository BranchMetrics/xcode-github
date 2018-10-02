/**
 @file          XGAStatusViewItem.m
 @package       xcode-github-app
 @brief         The status view detail line.

 @author        Edward Smith
 @date          September 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGAStatusViewItem.h"
#import "XGASettings.h"

@implementation XGAStatusViewItem

+ (instancetype) itemWithBot:(XGXcodeBot*)bot status:(XGXcodeBotStatus*)botStatus {
    if (bot == nil || botStatus == nil) return nil;
    XGAStatusViewItem *status = [XGAStatusViewItem new];
    if (!status) return status;

    status->_bot = bot;
    status->_botStatus = botStatus;

    status.server = botStatus.serverName;
    status.botName = botStatus.botName;

    status.statusSummary = [APFormattedString boldText:@"%@", botStatus.summaryString];
    status.statusDetail = botStatus.formattedDetailString;

    status.repository = [NSString stringWithFormat:@"%@/%@", bot.repoOwner, bot.repoName];

    // isXGAMonitored
    __auto_type tasks = [XGASettings shared].gitHubSyncTasks;
    for (XGAGitHubSyncTask *task in tasks) {
        if (status.server.length && status.bot.name.length &&
            [task.xcodeServer isEqualToString:status.server] &&
            [task.botNameForTemplate isEqualToString:status.bot.name])
            status->_isXGAMonitored = YES;
    }

    NSString*name = [XGXcodeBot gitHubPRNameFromBotName:botStatus.botName];
    if (name.length <= 0) name = bot.branch;
    status.branchOrPRName = name;
    if (!status.branchOrPRName.length) status.branchOrPRName = @"< Unknown >";
    if (status.isXGAMonitored)
        status.branchOrPRName = [NSString stringWithFormat:@"✓ %@", status.botName];


    status->_hasGitHubRepo = [bot.sourceControlRepository hasPrefix:@"github.com:"];
    status->_botIsFromTemplate = [NSNumber numberWithBool:[XGXcodeBot botNameIsCreatedFromTemplate:bot.name]];

templateBotName;

    NSString *result = [botStatus.result lowercaseString];
    if ([botStatus.currentStep containsString:@"completed"]) {

        NSString*imageName = @"RoundRed";
        if ([result containsString:@"succeeded"])
            imageName = @"RoundGreen";
        else
        if ([result containsString:@"unknown"])
            imageName = @"RoundAlert";
        else
        if ([result containsString:@"warning"])
            imageName = @"RoundYellow";
        else
        if ([result containsString:@"unknown"])
            imageName = @"RoundAlert";

        status.statusImage = [NSImage imageNamed:imageName];

    } else
    if ([botStatus.currentStep containsString:@"pending"]) {
        status.statusImage = [NSImage imageNamed:@"RoundGrey"];
    } else
        status.statusImage = [NSImage imageNamed:@"RoundBlue"];

    return status;
}

@end
