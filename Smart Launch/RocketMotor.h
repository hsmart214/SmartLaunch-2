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
@property (nonatomic, readonly) float loadedMass;
@property (nonatomic, readonly) float propellantMass;
@property (nonatomic, readonly) float totalImpulse;
@property (nonatomic, readonly) float peakThrust;
@property (nonatomic, readonly) NSString *impulseClass;
@property (nonatomic, readonly) NSUInteger diameter;
@property (nonatomic, readonly) float length;
@property (nonatomic, readonly) NSString *manufacturer;
@property (nonatomic, readonly) NSArray *delays;              // These are kept as an array of NSString* (may be "P")
@property (nonatomic, readonly) NSArray *times;
@property (nonatomic, readonly) NSArray *thrusts;
@property (nonatomic) float startDelay;
@property (nonatomic, readonly)float burnoutTime;   // this takes into account the startDelay


- (float)thrustAtTime:(float)time;
- (float)massAtTime:(float)time;
- (NSString *)nextImpulseClass;

- (float)fractionOfImpulseClass;

+ (RocketMotor *)motorWithMotorDict: (NSDictionary *)motorDict;
+ (NSArray *)manufacturerNames;
+ (NSDictionary *)manufacturerDict;
+ (NSArray *)hybridManufacturerNames;
+ (NSArray *)impulseClasses;
+ (NSArray *)impulseLimits;
+ (NSString *)impulseClassForTotalImpulse:(float)totalImpulse;
+ (NSArray *)motorDiameters;
+ (RocketMotor *)defaultMotor;  // in the first release this will be the 24mm Estes D12
+ (NSArray *)everyMotor;
+ (double)totalImpulseOfMotorWithName: (NSString *)motorName;

- (NSDictionary *)motorDict;

@end
