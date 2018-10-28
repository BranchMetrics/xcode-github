/**
 @file          XGCommandOptions.m
 @package       xcode-github
 @brief         Command options for the xcode-github app.

 @author        Edward Smith
 @date          March 7, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

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
        {"password",    required_argument,  NULL, 'p'},
        {"repeat",      no_argument,        NULL, 'r'},
        {"status",      no_argument,        NULL, 's'},
        {"template",    required_argument,  NULL, 't'},
        {"user",        required_argument,  NULL, 'u'},
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
        case 'p':   self.xcodeServerPassword = [self.class stringFromParameter]; break;
        case 'r':   self.repeatForever = YES; break;
        case 's':   self.showStatusOnly = YES; break;
        case 't':   self.templateBotName = [self.class stringFromParameter]; break;
        case 'u':   self.xcodeServerUser = [self.class stringFromParameter]; break;
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

+ (NSString*) helpString {
    NSString *kHelpString =
        @"xcode-github - Creates an Xcode test bots for new GitHub PRs.\n"
         "\n"
         "usage: xcode-github [-dhsVv] -g <github-auth-token>\n"
         "                 -t <bot-template> -x <xcode-server-domain-name>\n"
         "\n"
         "\n"
         "  -d, --dryrun\n"
         "      Dry run. Print what would be done.\n"
         "\n"
         "  -g, --github <github-auth-token>\n"
         "      A GitHub auth token that allows checking the status of a repo\n"
         "      and change a PR's status.\n"
         "\n"
         "  -h, --help\n"
         "      Print this help information.\n"
         "\n"
         "  -p, --password <password>\n"
         "      Password for the Xcode server.\n"
         "\n"
         "  -r, --repeat\n"
         "      Repeat updating the status forever, waiting 60 seconds between updates.\n"
         "\n"
         "  -s, --status\n"
         "      Only print the status of the xcode server bots and quit.\n"
         "\n"
         "  -t --template <bot-template>\n"
         "      An existing bot on the xcode server that is used as a template\n"
         "      for the new GitHub PR bots.\n"
         "\n"
         "  -u, --user <user>\n"
         "      User for the Xcode server.\n"
         "\n"
         "  -V, --version\n"
         "      Show version and exit.\n"
         "\n"
         "  -v, --verbose\n"
         "      Verbose. Extra 'v' increases the verbosity.\n"
         "\n"
         "  -x, --xcodeserver <xcode-server-domain-name>\n"
         "      The network name of the xcode server.\n"
         "\n"
         ;
    return kHelpString;
}

@end
