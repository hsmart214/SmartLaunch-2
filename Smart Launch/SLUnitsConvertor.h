//
//  SLUnitsConvertor.h
//  Snoopy
//
//  Created by J. Howard Smart on 6/30/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLUnitsConvertor : NSObject

+(SLUnitsConvertor *)sharedUnitsConvertor;

+(NSString *)defaultUnitForKey:(NSString *)key;

+(void)setDefaultUnit:(NSString *)unit forKey:(NSString *)key;

+(NSNumber *)metricStandardOf:(NSNumber *)dimension forKey:(NSString *)dimKey;

+(NSNumber *)displayUnitsOf:(NSNumber *)dimension forKey:(NSString *)dimKey;

+(NSString *)displayStringForKey:(NSString *)dimKey;

@end
