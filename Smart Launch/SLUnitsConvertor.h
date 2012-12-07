//
//  SLUnitsConvertor.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/30/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLUnitsConvertor : NSObject

// SLUnitsConvertor is a actually only meant to be accessed through its class methods.  You should not need to create a singleton instance - there are no instance variables

+(SLUnitsConvertor *)sharedUnitsConvertor;

+(NSString *)defaultUnitForKey:(NSString *)key;

+(void)setDefaultUnit:(NSString *)unit forKey:(NSString *)key;

+(NSNumber *)metricStandardOf:(NSNumber *)dimension forKey:(NSString *)dimKey;

+(NSNumber *)displayUnitsOf:(NSNumber *)dimension forKey:(NSString *)dimKey;

+(NSString *)displayStringForKey:(NSString *)dimKey;

@end
