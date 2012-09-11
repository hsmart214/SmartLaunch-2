//
//  RocketMotor.h
//  SafeLaunchMotorPicker
//
//  Created by J. Howard Smart on 6/16/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NAME_KEY @"motorName"
#define IMPULSE_KEY @"impulseClass"
#define MAN_KEY @"motorManufacturer"
#define MOTOR_MASS_KEY @"motorMass"
#define PROP_MASS_KEY @"propellantMass"
#define DELAYS_KEY @"delaysAvailable"
#define THRUST_KEY @"thrustArray"
#define TIME_KEY @"timeArray"
#define MOTOR_DIAM_KEY @"motorDiameter"
#define MOTOR_LENGTH_KEY @"motorLength"


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

+ (RocketMotor *)motorWithMotorDict: (NSDictionary *)motorDict;
+ (NSArray *)manufacturerNames;
+ (NSArray *)impulseClasses;
+ (NSArray *)motorDiameters;
+ (RocketMotor *)defaultMotor;  // in the first release this will be the 24mm Estes D12


- (NSDictionary *)motorDict;

@end
