//
//  RocketMotor.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/16/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RocketMotor : NSObject
// An immutable class representing the characteristics of a rocket motor, including
// static data, plus thrust curve data, methods to calculate thrust at arbitrary 
// times, and integrate the thrust curve to obtain total impulse.  Also calculates
// the peak thrust and burnout time, useful for graphing the thrust curve.
// The class only deals with kg-m-s metric values, conversion being a view controller job.

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSNumber *loadedMass;
@property (nonatomic, readonly) NSNumber *propellantMass;
@property (nonatomic, readonly) NSNumber *totalImpulse;
@property (nonatomic, readonly) NSNumber *peakThrust;
@property (nonatomic, readonly) NSString *impulseClass;
@property (nonatomic, readonly) NSNumber *diameter;
@property (nonatomic, readonly) NSNumber *length;
@property (nonatomic, readonly) NSString *manufacturer;
@property (nonatomic, readonly) NSArray *delays;              // These are kept as an array of NSString* (may be "P")
@property (nonatomic, readonly) NSArray *times;
@property (nonatomic, readonly) NSArray *thrusts;


- (CGFloat)thrustAtTime:(CGFloat)time;
- (CGFloat)massAtTime:(CGFloat)time;

- (float)fractionOfImpulseClass;

+ (RocketMotor *)motorWithMotorDict: (NSDictionary *)motorDict;
+ (NSArray *)manufacturerNames;
+ (NSDictionary *)manufacturerDict;
+ (NSArray *)hybridManufacturerNames;
+ (NSArray *)impulseClasses;
+ (NSString *)impulseClassForTotalImpulse:(NSNumber *)totalImpulse;
+ (NSArray *)motorDiameters;
+ (RocketMotor *)defaultMotor;  // in the first release this will be the 24mm Estes D12
+ (NSArray *)everyMotor;

- (NSDictionary *)motorDict;

@end
