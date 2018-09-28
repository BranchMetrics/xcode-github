/**
 @file          XGAAddServerPanel.h
 @package       xcode-github-app
 @brief         A panel to select a server.

 @author        Edward Smith
 @date          September 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Cocoa/Cocoa.h>
#import "XGASettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface XGAAddServerPanel : NSPanel
@property (strong) IBOutlet XGAServer*server;
@end

NS_ASSUME_NONNULL_END
