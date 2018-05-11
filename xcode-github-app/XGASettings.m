//
//  XGASettings.m
//  xcode-github-app
//
//  Created by Edward on 4/24/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGASettings.h"
#import "BNCKeyChain.h"
#import "BNCLog.h"

NSString*const kXGAServiceName = @"io.branch.XcodeGitHubService";

#pragma mark XGAServerGitHubSyncTask

@implementation XGAServerGitHubSyncTask

- (NSDictionary*_Nonnull) dictionary {
    NSMutableDictionary *d = [NSMutableDictionary new];
    d[@"xcodeServerName"] = self.xcodeServerName;
    d[@"gitHubRepo"] = self.gitHubRepo;
    d[@"templateBotName"] = self.templateBotName;
    return d;
}

+ (XGAServerGitHubSyncTask*_Nonnull) serverGitHubSyncTaskWithDictionary:(NSDictionary*_Nonnull)dictionary {
    XGAServerGitHubSyncTask*task = [XGAServerGitHubSyncTask new];
    task->_xcodeServerName = dictionary[@"xcodeServerName"];
    task->_gitHubRepo = dictionary[@"gitHubRepo"];
    task->_templateBotName = dictionary[@"templateBotName"];
    return task;
}

- (void) setXcodeServerName:(NSString*)serverName userPassword:(NSString*)userPassword {
    self->_xcodeServerName = serverName;
    if (!serverName) return;
    NSError *error =
        [BNCKeyChain storeValue:userPassword
            forService:kXGAServiceName
            key:serverName
            cloudAccessGroup:nil];
    if (error) BNCLogError(@"Error saving password for Xcode server '%@': %@.", serverName, error);
}

- (void) setGitHubRepo:(NSString*)gitHubRepo gitHubToken:(NSString*)token {
    self->_gitHubRepo = gitHubRepo;
    if (!gitHubRepo) return;
    NSError *error =
        [BNCKeyChain storeValue:token
            forService:kXGAServiceName
            key:gitHubRepo
            cloudAccessGroup:nil];
    if (error) BNCLogError(@"Error saving token for GitHub repo '%@': %@.", gitHubRepo, error);
}

- (NSString*) xcodeServerUserPassword {
    NSError*error = nil;
    NSString *userPassword =
        [BNCKeyChain retrieveValueForService:kXGAServiceName key:self.xcodeServerName error:&error];
    return (error) ? nil : userPassword;
}

- (NSString*) gitHubToken {
    NSError*error = nil;
    NSString *token =
        [BNCKeyChain retrieveValueForService:kXGAServiceName key:self.gitHubRepo error:&error];
    return (error) ? nil : token;
}

@end

#pragma mark - XGASettings

@implementation XGASettings

+ (XGASettings*_Nonnull) shared {
    static dispatch_once_t onceToken = 0;
    static XGASettings* sharedSettings = nil;
    dispatch_once(&onceToken, ^ {
        sharedSettings = [XGASettings new];
        [sharedSettings load];
    });
    return sharedSettings;
}

#if 0 // eDebug - Set some testing values:

- (void) load {
    @synchronized(self) {
        self.serverGitHubSyncTasks = [NSMutableArray new];
        NSArray* array = [[NSUserDefaults standardUserDefaults] objectForKey:@"serverGitHubSyncTasks"];
        if ([array isKindOfClass:NSArray.class]) {
            for (NSDictionary *d in array) {
                if (![d isKindOfClass:NSDictionary.class]) continue;
                XGAServerGitHubSyncTask*task = [XGAServerGitHubSyncTask serverGitHubSyncTaskWithDictionary:d];
                if (task) [self.serverGitHubSyncTasks addObject:task];
            }
        }
    }
}

#else

- (void) load {
    @synchronized(self) {
        XGAServerGitHubSyncTask*task = nil;
        self.serverGitHubSyncTasks = [NSMutableArray new];
/*
        task = [XGAServerGitHubSyncTask new];
        [task setXcodeServerName:@"esmith.local" userPassword:nil];
        task.templateBotName = @"Branch-TestBed Test Bot";
        [task setGitHubRepo:@"BranchMetrics:ios-branch-deep-linking"
            gitHubToken:@"13e499f7d9ba4fca42e4715558d1e5bc30a6a4e9"];
        [self.serverGitHubSyncTasks addObject:task];

        task = [XGAServerGitHubSyncTask new];
        [task setXcodeServerName:@"esmith.local" userPassword:nil];
        task.templateBotName = @"BranchLabs Bot";
        [task setGitHubRepo:@"BranchMetrics:BranchLabs-iOS"
            gitHubToken:@"13e499f7d9ba4fca42e4715558d1e5bc30a6a4e9"];
        [self.serverGitHubSyncTasks addObject:task];
*/
        task = [XGAServerGitHubSyncTask new];
        [task setXcodeServerName:@"esmith.local" userPassword:nil];
        task.templateBotName = @"xcode-github-tests master";
        [task setGitHubRepo:@"BranchMetrics:xcode-github"
            gitHubToken:@"13e499f7d9ba4fca42e4715558d1e5bc30a6a4e9"];
        [self.serverGitHubSyncTasks addObject:task];

        NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
        self.firstTimeRun = ![defaults boolForKey:@"firstTimeRun"];
        if (self.firstTimeRun) {
            [self setInitialDefaults];
            return;
        }
        self.dryRun = [defaults boolForKey:@"dryRun"];
        self.refreshSeconds = [defaults doubleForKey:@"refreshSeconds"];
        [self validate];
    }
}

#endif

- (void) validate {
    self.refreshSeconds = MAX(15.0, MIN(self.refreshSeconds, 60.0*60.0*24.0*1.0));
}

- (void) setInitialDefaults {
    self.firstTimeRun = NO;
    self.dryRun = NO;
    self.refreshSeconds = 30;
    [self validate];
}

- (void) save {
    @synchronized(self) {
        [self validate];
        NSMutableArray*array = [NSMutableArray new];
        for (XGAServerGitHubSyncTask*task in self.serverGitHubSyncTasks) {
            NSDictionary *d = task.dictionary;
            [array addObject:d];
        }
        NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:array forKey:@"serverGitHubSyncTasks"];
        [defaults setBool:self.dryRun forKey:@"dryRun"];
        [defaults setBool:self.firstTimeRun forKey:@"firstTimeRun"];
        [defaults setDouble:self.refreshSeconds forKey:@"refreshSeconds"];
    }
}

@end
