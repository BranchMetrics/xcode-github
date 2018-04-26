/**
 @file          BNCUtilities.h
 @package       Branch-SDK
 @brief         Miscellaneous Utilities.

 @author        Edward Smith
 @date          May 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

@import Foundation;

///@group Blocks and Threads
#pragma mark - Blocks and Threads

static inline dispatch_time_t BNCDispatchTimeFromSeconds(NSTimeInterval seconds) {
	return dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC);
}

static inline void BNCAfterSecondsPerformBlockOnMainThread(NSTimeInterval seconds, dispatch_block_t block) {
	dispatch_after(BNCDispatchTimeFromSeconds(seconds), dispatch_get_main_queue(), block);
}

static inline void BNCPerformBlockOnMainThreadAsync(dispatch_block_t block) {
    dispatch_async(dispatch_get_main_queue(), block);
}

static inline uint64_t BNCNanoSecondsFromTimeInterval(NSTimeInterval interval) {
    return interval * ((NSTimeInterval) NSEC_PER_SEC);
}

static inline void BNCSleepForTimeInterval(NSTimeInterval seconds) {
    double secPart = trunc(seconds);
    double nanoPart = trunc((seconds - secPart) * ((double)NSEC_PER_SEC));
    struct timespec sleepTime;
    sleepTime.tv_sec = (__typeof(sleepTime.tv_sec)) secPart;
    sleepTime.tv_nsec = (__typeof(sleepTime.tv_nsec)) nanoPart;
    nanosleep(&sleepTime, NULL);
}

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
