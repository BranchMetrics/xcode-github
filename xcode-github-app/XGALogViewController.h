//
//  XGALogViewController.h
//  xcode-github-app
//
//  Created by Edward on 5/8/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface XGALogViewController : NSViewController
+ (void) startLog;
+ (instancetype) loadController;
@property (strong) IBOutlet NSWindow*window;
@end

NS_ASSUME_NONNULL_END
