//
//  XGALogViewController.h
//  xcode-github-app
//
//  Created by Edward on 5/8/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BNCLog.h"

#pragma mark XGALogRow

@interface XGALogRow : NSObject
@property (nonatomic, strong) NSDate*date;
@property (nonatomic, assign) BNCLogLevel logLevel;
@property (nonatomic, strong) NSString*logMessage;
@end

#pragma mark - XGALogViewController

@interface XGALogViewController : NSViewController
@property (strong) NSMutableArray<XGALogRow*>*logArray;
@end
