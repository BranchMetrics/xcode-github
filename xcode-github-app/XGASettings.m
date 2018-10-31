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
#import <XcodeGitHub/XcodeGitHub.h>

#pragma mark XGAServer

NSString*const kXGAServiceName = @"io.branch.XcodeGitHub";

NSString*_Nonnull XGACleanString(NSString*_Nullable string) {
    if (string == nil) return @"";
    if (![string isKindOfClass:NSString.class]) {
        string = ([string respondsToSelector:@selector(description)]) ? [string description] : @"";
    }
    return [string stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@implementation XGAServer

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) return self;
    self.server = XGACleanString([aDecoder decodeObjectOfClass:NSString.class forKey:@"_server"]);
    self.user = XGACleanString([aDecoder decodeObjectOfClass:NSString.class forKey:@"_user"]);
    self.password = @"";
    if (self.server.length != 0 && self.user.length != 0) {
        NSError*error = nil;
        self.password =
            [BNCKeyChain retrieveValueForService:self.server
                key:self.user
                error:&error];
        if (error) {
            BNCLog(@"Can't retrieve password: %@.", error);
            self.password = @"";
        }
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    @synchronized (self) {
        [aCoder encodeObject:self.server forKey:@"_server"];
        [aCoder encodeObject:self.user forKey:@"_user"];
        if (self.server.length != 0 && self.user.length != 0) {
            NSError *error =
                [BNCKeyChain storeValue:self.password
                    forService:self.server
                    key:self.user
                    cloudAccessGroup:nil];
            if (error) BNCLog(@"Can't save password: %@.", error);
        }
    }
}

@end

#pragma mark - XGAGitHubSyncTask

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
    self.dryRun = NO;
    self.showDebugMessages = NO;
    self.refreshSeconds = 60.0;
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

- (NSString*) gitHubToken {
    @synchronized (self) {
        NSError*error = nil;
        NSString*token =
            [BNCKeyChain retrieveValueForService:kXGAServiceName
                key:@"GitHubToken"
                error:&error];
        if (error) BNCLog(@"Can't retrieve GitHubToken: %@.", error);
        return token;
    }
}

- (void) setGitHubToken:(NSString *)token {
    @synchronized (self) {
        NSError *error =
            [BNCKeyChain storeValue:token
                forService:kXGAServiceName
                key:@"GitHubToken"
                cloudAccessGroup:nil];
        if (error) BNCLog(@"Can't save GitHubToken: %@.", error);
    }
}

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
    self.dryRun = NO;
    self.showDebugMessages = NO;
    self.refreshSeconds = 60.0;
    self.gitHubToken = @"";
    [self.servers removeAllObjects];
    [self.gitHubSyncTasks removeAllObjects];
}

- (void) validate {
    self.refreshSeconds = MAX(15.0, MIN(self.refreshSeconds, 60.0*60.0*24.0*1.0));

    // Assure that servers are unique:
    NSMutableDictionary*d = NSMutableDictionary.new;
    for (XGAServer*server in self.servers) {
        if (server.server.length) d[server.server] = server;
    }
    [self.servers removeAllObjects];
    [self.servers addObjectsFromArray:d.allValues];

    // Assure that tasks are unique:
    [d removeAllObjects];
    for (XGAGitHubSyncTask*task in self.gitHubSyncTasks) {
        NSString*string = [NSString stringWithFormat:@"%@:%@", task.xcodeServer, task.botNameForTemplate];
        d[string] = task;
    }
    [self.gitHubSyncTasks removeAllObjects];
    [self.gitHubSyncTasks addObjectsFromArray:d.allValues];
}

@end
