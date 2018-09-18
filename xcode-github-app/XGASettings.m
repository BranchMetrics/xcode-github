/**
 @file          XGASettings.m
 @package       xcode-github-app
 @brief         The persistent settings store for the app.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGASettings.h"
#import "BNCKeyChain.h"
#import "BNCLog.h"

NSString*const kXGAServiceName = @"io.branch.XcodeGitHubService";

@implementation XGAServerSetting
@end

#pragma mark XGAGitHubSyncTask

@implementation XGAGitHubSyncTask

- (NSDictionary*_Nonnull) dictionary {
    NSMutableDictionary *d = [NSMutableDictionary new];
    d[@"xcodeServer"] = self.xcodeServer;
    d[@"gitHubRepo"] = self.gitHubRepo;
    d[@"templateBotName"] = self.templateBotName;
    return d;
}

+ (XGAGitHubSyncTask*_Nonnull) gitHubSyncTaskWithDictionary:(NSDictionary*_Nonnull)dictionary {
    XGAGitHubSyncTask*task = [XGAGitHubSyncTask new];
    if (!task) return task;
    task->_xcodeServer = dictionary[@"xcodeServer"];
    task->_gitHubRepo = dictionary[@"gitHubRepo"];
    task->_templateBotName = dictionary[@"templateBotName"];
    return task;
}

- (void) setXcodeServerName:(NSString*)serverName userPassword:(NSString*)userPassword {
    @synchronized(self) {
        self->_xcodeServer = serverName;
        if (!serverName) return;
        NSError *error =
            [BNCKeyChain storeValue:userPassword
                forService:kXGAServiceName
                key:serverName
                cloudAccessGroup:nil];
        if (error) BNCLogError(@"Error saving password for Xcode server '%@': %@.", serverName, error);
    }
}

- (void) setGitHubRepo:(NSString*)gitHubRepo gitHubToken:(NSString*)token {
    @synchronized(self) {
        self->_gitHubRepo = gitHubRepo;
        if (!gitHubRepo) return;
        NSError *error =
            [BNCKeyChain storeValue:token
                forService:kXGAServiceName
                key:gitHubRepo
                cloudAccessGroup:nil];
        if (error) BNCLogError(@"Error saving token for GitHub repo '%@': %@.", gitHubRepo, error);
    }
}

- (NSString*) xcodeServerUserPassword {
    @synchronized(self) {
        NSError*error = nil;
        NSString *userPassword =
            [BNCKeyChain retrieveValueForService:kXGAServiceName key:self.xcodeServer error:&error];
        return (error) ? nil : userPassword;
    }
}

- (NSString*) gitHubToken {
    NSError*error = nil;
    NSString *token =
        [BNCKeyChain retrieveValueForService:kXGAServiceName key:self.gitHubRepo error:&error];
    return (error) ? nil : token;
}

@end

#pragma mark - XGASettings

@interface XGASettings () {
    NSMutableArray<XGAServerSetting*>*_servers;
    NSMutableArray<XGAGitHubSyncTask*>*_gitHubSyncTasks;
}
@end

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
                XGAServerGitHubSyncTask*task =
                    [XGAServerGitHubSyncTask serverGitHubSyncTaskWithDictionary:d];
                if (task) [self.serverGitHubSyncTasks addObject:task];
            }
        }
    }
}

#else

- (void) load {
    @synchronized(self) {
        XGAGitHubSyncTask*task = nil;
        self.gitHubSyncTasks = [NSMutableArray new];
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

/*
        task = [XGAServerGitHubSyncTask new];
        [task setXcodeServerName:@"esmith.local" userPassword:nil];
        task.templateBotName = @"xcode-github-tests master";
        [task setGitHubRepo:@"BranchMetrics:xcode-github"
            gitHubToken:@"13e499f7d9ba4fca42e4715558d1e5bc30a6a4e9"];
        [self.serverGitHubSyncTasks addObject:task];
*/
        NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
        self.hasRunBefore = [defaults boolForKey:@"hasRunBefore"];
        if (!self.hasRunBefore) [self setInitialDefaults];
        self.dryRun = [defaults boolForKey:@"dryRun"];
        self.showDebugMessages = [defaults boolForKey:@"showDebugMessages"];
        self.refreshSeconds = [defaults doubleForKey:@"refreshSeconds"];
        [self validate];
    }
}

#endif

#pragma mark - Setters/Getters

- (NSMutableArray<XGAServerSetting*>*) servers {
    @synchronized (self) {
        if (_servers == nil) _servers = [NSMutableArray new];
        return _servers;
    }
}

- (void) setServers:(NSMutableArray<XGAServerSetting*>*)servers_ {
    @synchronized (self) {
        _servers = servers_;
    }
}

- (NSMutableArray<XGAGitHubSyncTask*>*) gitHubSyncTasks {
    @synchronized (self) {
        if (_gitHubSyncTasks == nil) _gitHubSyncTasks = [NSMutableArray new];
        return _gitHubSyncTasks;
    }
}

- (void) setGitHubSyncTasks:(NSMutableArray<XGAGitHubSyncTask*>*)gitHubSyncTasks_ {
    @synchronized (self) {
        _gitHubSyncTasks = gitHubSyncTasks_;
    }
}

NSMutableArray<XGAGitHubSyncTask*>*gitHubSyncTasks;

- (void) validate {
    self.refreshSeconds = MAX(15.0, MIN(self.refreshSeconds, 60.0*60.0*24.0*1.0));
}

- (void) setInitialDefaults {
    self.hasRunBefore = YES;
    self.dryRun = NO;
    self.refreshSeconds = 30;
    [self save];
}

- (void) save {
    @synchronized(self) {
        [self validate];
        NSMutableArray*array = [NSMutableArray new];
        for (XGAGitHubSyncTask*task in self.gitHubSyncTasks) {
            NSDictionary *d = task.dictionary;
            [array addObject:d];
        }
        NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:array forKey:@"gitHubSyncTasks"];
        [defaults setBool:self.dryRun forKey:@"dryRun"];
        [defaults setBool:self.hasRunBefore forKey:@"hasRunBefore"];
        [defaults setDouble:self.refreshSeconds forKey:@"refreshSeconds"];
        [defaults setBool:self.showDebugMessages forKey:@"showDebugMessages"];
    }
}

@end
