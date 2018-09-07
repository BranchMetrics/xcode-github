/**
 @file          XGSettings.m
 @package       xcode-github
 @brief         Settings store for xcode-github.

 @author        Edward Smith
 @date          September 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGSettings.h"

@interface NSMutableDictionary (XG)
+ (instancetype _Nonnull) mutableDeepCopy:(NSDictionary*)dictionary;
@end

@implementation NSMutableDictionary (XG)

+ (instancetype _Nonnull) mutableDeepCopy:(NSDictionary*)dictionary {
    NSError*error = nil;
    NSMutableDictionary*result = nil;
    if (!dictionary) goto exit;

    {
    NSData*data =
        [NSPropertyListSerialization dataWithPropertyList:dictionary
            format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if (!data || error) goto exit;

    result =
        [NSPropertyListSerialization propertyListWithData:data
            options:NSPropertyListMutableContainersAndLeaves format:NULL error:&error];
    }
    
exit:
    if (error) NSLog(@"Error creating mutable dictionary: %@.", error);
    if (!result) result = [NSMutableDictionary new];
    return result;
}

@end

#pragma mark - XGSettings

static NSString*const kGitHubStatusKey = @"githubStatus";

@implementation XGSettings

+ (XGSettings*_Nonnull) sharedSettings {
    static dispatch_once_t onceToken = 0;
    static XGSettings*_sharedSettings = nil;
    dispatch_once(&onceToken, ^ {
        _sharedSettings = [[XGSettings alloc] init];
    });
    return _sharedSettings;
}

- (void) expireOldData {
    @synchronized(self) {
        NSMutableArray*deletions = [NSMutableArray new];
        NSMutableDictionary*dictionary =
            [NSMutableDictionary mutableDeepCopy:
                [[NSUserDefaults standardUserDefaults] objectForKey:kGitHubStatusKey]];
        NSTimeInterval kOneDay = 24.0*60.0*60.0;
        for (NSString*key in dictionary.keyEnumerator) {
            NSDate*date = dictionary[key][@"date"];
            if (!date || [date timeIntervalSinceNow] < - kOneDay) {
                [deletions addObject:key];
            }
        }
        [dictionary removeObjectsForKeys:deletions];
        [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:kGitHubStatusKey];
    }
}

- (NSString*) keyForPR:(XGGitHubPullRequest *)pr {
    return [NSString stringWithFormat:@"%@-%@-%@", pr.repoOwner, pr.repoName, pr.branch];
}

- (void) setGitHubStatus:(NSString*)status forPR:(XGGitHubPullRequest *)pr {
    @synchronized(self) {
        [self expireOldData];
        if (!status) return;
        NSMutableDictionary*dictionary =
            [NSMutableDictionary mutableDeepCopy:
                [[NSUserDefaults standardUserDefaults] dictionaryForKey:kGitHubStatusKey]];
        dictionary[[self keyForPR:pr]] = @{
            @"date":    [NSDate date],
            @"status":  status
        };
        [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:kGitHubStatusKey];
    }
}

- (NSString*) gitHubStatusForPR:(XGGitHubPullRequest *)pr {
    @synchronized(self) {
        [self expireOldData];
        NSMutableDictionary*dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:kGitHubStatusKey];
        return dictionary[[self keyForPR:pr]][@"status"];
    }
}

NSMutableDictionary*_Nonnull XGMutableDictionaryWithDictionary(NSDictionary*_Nullable dictionary) {
    if ([dictionary isKindOfClass:NSMutableDictionary.class])
        return (NSMutableDictionary*) dictionary;
    else
    if ([dictionary isKindOfClass:NSDictionary.class])
        return [NSMutableDictionary dictionaryWithDictionary:dictionary];
    else
        return [NSMutableDictionary new];
}

@end
