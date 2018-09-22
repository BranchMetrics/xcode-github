/**
 @file          BNCGeometry.h
 @package       Apple-Shared-Source
 @brief         Utilities for working with geometry.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

///@group Geometric Functions
#pragma mark Geometric Functions

static inline CGRect BNCCenterRectOverRect(CGRect rectToCenter, CGRect overRect) {
    return CGRectMake(
        overRect.origin.x + ((overRect.size.width - rectToCenter.size.width)/2.0)
       ,overRect.origin.y + ((overRect.size.height - rectToCenter.size.height)/2.0)
       ,rectToCenter.size.width
       ,rectToCenter.size.height
    );
}

static inline CGRect BNCCenterRectOverRectX(CGRect rectToCenter, CGRect overRect) {
   return CGRectMake(
         overRect.origin.x + ((overRect.size.width - rectToCenter.size.width)/2.0)
        ,rectToCenter.origin.y
        ,rectToCenter.size.width
        ,rectToCenter.size.height
    );
}

static inline CGRect BNCCenterRectOverRectY(CGRect rectToCenter, CGRect overRect) {
    return CGRectMake(
         rectToCenter.origin.x
        ,overRect.origin.y + ((overRect.size.height - rectToCenter.size.height)/2.0)
        ,rectToCenter.size.width
        ,rectToCenter.size.height
    );
}

static inline CGRect BNCCenterRectOverPoint(CGRect rectToCenter, CGPoint referencePoint) {
    return CGRectMake(
        referencePoint.x - (rectToCenter.size.width / 2.0),
        referencePoint.y - (rectToCenter.size.height / 2.0),
        rectToCenter.size.width,
        rectToCenter.size.height
    );
}

static inline CGPoint BNCCenterPointOfRect(CGRect r) {
    CGPoint p;
    p.x = r.origin.x + (r.size.width / 2.00);
    p.y = r.origin.y + (r.size.height / 2.00);
    return p;
}
