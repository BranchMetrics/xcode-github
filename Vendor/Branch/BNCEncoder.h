/**
 @file          BNCEncoder.h
 @package       Branch
 @brief         A light weight, general purpose object encoder.

 @author        Edward Smith
 @date          June 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCEncoder : NSObject

+ (NSError*_Nullable) decodeInstance:(id)instance
        withCoder:(NSCoder*)coder
        classes:(NSSet<Class>*_Nullable)classes
        ignoring:(NSArray<NSString*>*_Nullable)ignoreIvars;

+ (NSError*_Nullable) encodeInstance:(id)instance
        withCoder:(NSCoder*)coder
        ignoring:(NSArray<NSString*>*_Nullable)ignoreIvars;

+ (NSError*_Nullable) copyInstance:(id)toInstance
        fromInstance:(id)fromInstance
        ignoring:(NSArray<NSString*>*_Nullable)ignoreIvars;

+ (NSData*_Nullable) dataFromObject:(NSObject*)object
        ignoringIvars:(NSArray*_Nullable)ignoreIvars
        error:(NSError*_Nullable __autoreleasing *_Nullable)error_;

+ (NSError*_Nullable) decodeObject:(NSObject*)object
        fromData:(NSData*)data
        classes:(NSSet<Class>*)classes
        ignoringIvars:(NSArray*_Nullable)ignoreIvars;

@end

#pragma mark - BNCCoding

@interface BNCCoding : NSObject <NSSecureCoding>
+ (NSArray<NSString*>*) ignoreIvars;
+ (BOOL) supportsSecureCoding;
- (instancetype) initWithCoder:(NSCoder *)aDecoder;
- (void) encodeWithCoder:(NSCoder *)aCoder;
@end

NS_ASSUME_NONNULL_END
