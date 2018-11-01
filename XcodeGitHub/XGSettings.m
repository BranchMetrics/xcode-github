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

@interface XGSettings () {
    NSTimeInterval _dataExpirationSeconds;
}
@end

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

- (instancetype) init {
    self = [super init];
    if (!self) return self;
    self.dataExpirationSeconds = 60.0*60.0*24.0*7.0;
    return self;
}

- (NSTimeInterval) dataExpirationSeconds {
    @synchronized(self) {
        return _dataExpirationSeconds;
    }
}

- (void) setDataExpirationSeconds:(NSTimeInterval)dataExpirationSeconds_ {
    @synchronized(self) {
        _dataExpirationSeconds = - fabs(dataExpirationSeconds_);
    }
}

- (void) expireOldData {
    @synchronized(self) {
        NSMutableArray*deletions = [NSMutableArray new];
        NSMutableDictionary*dictionary =
            [NSMutableDictionary mutableDeepCopy:
                [[NSUserDefaults standardUserDefaults] objectForKey:kGitHubStatusKey]];
        NSTimeInterval age = self.dataExpirationSeconds;
        for (NSString*key in dictionary.keyEnumerator) {
            NSDate*date = dictionary[key][@"date"];
            if (!date || [date timeIntervalSinceNow] < age) {
                [deletions addObject:key];
            }
        }
        [dictionary removeObjectsForKeys:deletions];
        [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:kGitHubStatusKey];
    }
}

- (NSString*) keyForRepoOwner:(NSString*)repoOwner
        repoName:(NSString*)repoName
        branch:(NSString*)branch {
    return [NSString stringWithFormat:@"%@-%@-%@", repoOwner, repoName, branch];
}

- (void) setGitHubStatus:(NSString*)status
        forRepoOwner:(NSString*)repoOwner
        repoName:(NSString*)repoName
        branch:(NSString*)branch {
    @synchronized(self) {
        [self expireOldData];
        if (!status) return;
        NSMutableDictionary*dictionary =
            [NSMutableDictionary mutableDeepCopy:
                [[NSUserDefaults standardUserDefaults]
                    dictionaryForKey:kGitHubStatusKey]];
        dictionary[[self keyForRepoOwner:repoOwner repoName:repoName branch:branch]] = @{
            @"date":    [NSDate date],
            @"status":  status
        };
        [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:kGitHubStatusKey];
    }
}

- (NSString*_Nullable) gitHubStatusForRepoOwner:(NSString*)repoOwner
        repoName:(NSString*)repoName
        branch:(NSString*)branch {
    @synchronized(self) {
        [self expireOldData];
        NSDictionary*dictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kGitHubStatusKey];
        return dictionary[[self keyForRepoOwner:repoOwner repoName:repoName branch:branch]][@"status"];
    }
}

- (void) deleteGitHubStatusForRepoOwner:(NSString*)repoOwner
        repoName:(NSString*)repoName
        branch:(NSString*)branch {
    @synchronized(self) {
        [self expireOldData];
        NSMutableDictionary*dictionary =
            [NSMutableDictionary mutableDeepCopy:
                [[NSUserDefaults standardUserDefaults]
                    dictionaryForKey:kGitHubStatusKey]];
        dictionary[[self keyForRepoOwner:repoOwner repoName:repoName branch:branch]] = nil;
        [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:kGitHubStatusKey];
    }
}

- (void) clear {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGitHubStatusKey];
}

@end
