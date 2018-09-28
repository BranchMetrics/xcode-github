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


#pragma mark XGAServer

NSString*const kXGAServiceName = @"io.branch.XcodeGitHubService";

@implementation XGAServer

+ (NSArray<NSString*>*) ignoreIvars {
    return @[ @"_password" ];
}

- (instancetype) init {
    self = [super init];
    if (!self) return self;
    _server = @"";
    _user = @"";
    return self;
}

- (NSString*) description {
    NSString *pass = self.password.length ? @"••••" : @"nil";
    return [NSString stringWithFormat:@"<%@ %p %@ %@ %@>",
        NSStringFromClass(self.class),
        (void*)self,
        self.server,
        self.user,
        pass];
}

/*
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
*/

@end

#pragma mark XGAGitHubSyncTask

@implementation XGAGitHubSyncTask
@end

#pragma mark - XGASettings

@interface XGASettings () {
    NSMutableArray<XGAServer*>*_servers;
    NSMutableArray<XGAGitHubSyncTask*>*_gitHubSyncTasks;
}
@end

@implementation XGASettings

- (instancetype) init {
    self = [super init];
    if (!self) return self;
    [self clear];
    return self;
}

+ (XGASettings*_Nonnull) shared {
    static dispatch_once_t onceToken = 0;
    static XGASettings* sharedSettings = nil;
    dispatch_once(&onceToken, ^ {
        sharedSettings = [XGASettings loadSettings];
    });
    return sharedSettings;
}

#pragma mark - Setters/Getters

- (NSMutableArray<XGAServer*>*) servers {
    @synchronized (self) {
        if (_servers == nil) _servers = [NSMutableArray new];
        return _servers;
    }
}

- (void) setServers:(NSMutableArray<XGAServer*>*)servers_ {
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

#pragma mark - Save and Load Settings

+ (instancetype) loadSettings {
    NSError*error = nil;
    XGASettings* settings = nil;
    NSData*data = [[NSUserDefaults standardUserDefaults] objectForKey:@"settings"];
    if (data) {
        settings = [[XGASettings alloc] init];
        error =
            [BNCEncoder decodeObject:settings
                fromData:data
                classes:[NSSet setWithObjects:XGAServer.class, XGAGitHubSyncTask.class, nil]
                ignoringIvars:nil];
        if (!error && [settings isKindOfClass:XGASettings.class]) {
            [settings validate];
            return settings;
        }
    }
    if (error) BNCLogError(@"Can't load settings: %@.", error);
    settings = [[XGASettings alloc] init];
    return settings;
}

- (void) save {
    @synchronized(self) {
        [self validate];
        NSError*error = nil;
        NSData*data = [BNCEncoder dataFromObject:self ignoringIvars:nil error:&error];
        if (error) BNCLogError(@"Error saving settings: %@.", error);
        if (data) [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"settings"];
    }
}

- (void) clear {
    self.dryRun = YES;
    self.showDebugMessages = YES;
    self.refreshSeconds = 60.0;
    self.gitHubToken = @"";
    [self.servers removeAllObjects];
    [self.gitHubSyncTasks removeAllObjects];
}

- (void) validate {
    self.refreshSeconds = MAX(15.0, MIN(self.refreshSeconds, 60.0*60.0*24.0*1.0));

    __auto_type indexSet = [NSMutableIndexSet new];
    for (NSInteger i = 0; i < self.servers.count; i++) {
        self.servers[i].server =
            [self.servers[i].server stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (self.servers[i].server.length <= 0) {
            [indexSet addIndex:i];
            continue;
        }
        for (NSInteger j = i+1; j < self.servers.count; j++) {
            if ([self.servers[i].server isEqualToString:self.servers[j].server]) {
                [indexSet addIndex:i];
            }
        }
    }
    [self.servers removeObjectsAtIndexes:indexSet];
}

@end
