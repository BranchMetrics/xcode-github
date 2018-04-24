//
//  XGCommandOptions.m
//  xcode-github
//
//  Created by Edward on 3/7/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGCommandOptions.h"
#include <getopt.h>

@implementation XGCommandOptions

- (instancetype _Nonnull) initWithArgc:(int)argc argv:(char*const _Nullable[_Nullable])argv {
    self = [super init];
    if (!self) return self;

    static struct option long_options[] = {
        {"dryrun",      no_argument,        NULL, 'd'},
        {"github",      required_argument,  NULL, 'g'},
        {"help",        no_argument,        NULL, 'h'},
        {"status",      no_argument,        NULL, 's'},
        {"template",    required_argument,  NULL, 't'},
        {"verbose",     no_argument,        NULL, 'v'},
        {"version",     no_argument,        NULL, 'V'},
        {"xcodeserver", required_argument,  NULL, 'x'},
        {0, 0, 0, 0}
    };

    int c = 0;
    do {
        int option_index = 0;
        c = getopt_long(argc, argv, "dg:hst:vVx:", long_options, &option_index);
        switch (c) {
        case -1:    break;
        case 'd':   self.dryRun = YES; break;
        case 'g':   self.githubAuthToken = [self.class stringFromParameter]; break;
        case 'h':   self.showHelp = YES; break;
        case 's':   self.showStatusOnly = YES; break;
        case 't':   self.templateBotName = [self.class stringFromParameter]; break;
        case 'v':   self.verbosity++; break;
        case 'V':   self.showVersion = YES; break;
        case 'x':   self.xcodeServerName = [self.class stringFromParameter]; break;
        default:    self.badOptionsError = YES; break;
        }
    } while (c != -1 && !self.badOptionsError);

    return self;
}

+ (NSString*) stringFromParameter {
    return [NSString stringWithCString:optarg encoding:NSUTF8StringEncoding];
}

+ (instancetype _Nonnull) testWithBranchSDK {
    XGCommandOptions*options = [[XGCommandOptions alloc] init];
    options.xcodeServerName = @"esmith.local";
    options.templateBotName = @"Branch-TestBed Test Bot";
    options.githubAuthToken = @"13e499f7d9ba4fca42e4715558d1e5bc30a6a4e9";
    options.dryRun = YES;
    options.showHelp = NO;
    options.showStatusOnly = NO;
    options.verbosity = 10;
    options.showVersion = NO;
    options.badOptionsError = 0;
    return options;
}

+ (instancetype _Nonnull) testWithBranchLabs {
    XGCommandOptions*options = [[XGCommandOptions alloc] init];
    options.xcodeServerName = @"esmith.local";
    options.templateBotName = @"BranchLabs Bot";
    options.githubAuthToken = @"13e499f7d9ba4fca42e4715558d1e5bc30a6a4e9";
    options.dryRun = YES;
    options.showHelp = NO;
    options.showStatusOnly = YES;
    options.verbosity = 0;//10;
    options.showVersion = NO;
    options.badOptionsError = 0;
    return options;
}

@end
