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
#import "BNCEncoder.h"
#import "BNCLog.h"

NSString*const kXGAServiceName = @"io.branch.XcodeGitHubService";

@implementation XGAServerSetting

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) return self;
    NSError*error = [BNCEncoder decodeInstance:self withCoder:aDecoder ignoring:@[@"_password"]];
    if (error) BNCLogError(@"Can't decode %@: %@", NSStringFromClass(self.class), error);
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    @synchronized (self) {
        NSError*error = [BNCEncoder encodeInstance:self withCoder:aCoder ignoring:@[@"_password"]];
        if (error) BNCLogError(@"Can't encode %@: %@", NSStringFromClass(self.class), error);
    }
}

- (NSString*) password {
    @synchronized (self) {
        NSString *password = nil;
        if (self.server.length) {
            NSError*error = nil;
                [BNCKeyChain retrieveValueForService:kXGAServiceName key:self.server error:&error];
            if (error) BNCLog(@"Can't retrieve password: %@.", error);
        }
        return password;
    }
}

- (void) setPassword:(NSString *)password {
    @synchronized (self) {
        if (self.server.length) {
            NSError *error =
                [BNCKeyChain storeValue:password
                    forService:kXGAServiceName
                    key:self.server
                    cloudAccessGroup:nil];
            if (error) BNCLog(@"Can't save password: %@.", error);
        }
    }
}

@end

#pragma mark XGAGitHubSyncTask

@implementation XGAGitHubSyncTask

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) return self;
    NSError*error = [BNCEncoder decodeInstance:self withCoder:aDecoder ignoring:@[@"_password"]];
    if (error) BNCLogError(@"Can't decode %@: %@", NSStringFromClass(self.class), error);
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    NSError*error = [BNCEncoder encodeInstance:self withCoder:aCoder ignoring:@[@"_password"]];
    if (error) BNCLogError(@"Can't encode %@: %@", NSStringFromClass(self.class), error);
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
        //XGAGitHubSyncTask*task = nil;
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
        NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.servers forKey:@"servers"];
        [defaults setObject:self.gitHubSyncTasks forKey:@"gitHubSyncTasks"];
        [defaults setBool:self.dryRun forKey:@"dryRun"];
        [defaults setBool:self.hasRunBefore forKey:@"hasRunBefore"];
        [defaults setDouble:self.refreshSeconds forKey:@"refreshSeconds"];
        [defaults setBool:self.showDebugMessages forKey:@"showDebugMessages"];
    }
}

@end
