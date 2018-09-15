/**
 @file          XGAAddServerPanel.h
 @package       xcode-github-app
 @brief         A panel to select a server.

 @author        Edward Smith
 @date          September 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Cocoa/Cocoa.h>

@interface XGAAddServerPanel : NSPanel
+ (instancetype) new;
@property (readonly) NSString*serverName;
@property (readonly) NSString*userName;
@property (readonly) NSString*password;
@end
