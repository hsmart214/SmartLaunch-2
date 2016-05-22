//
//  Rocket.h
//  Smart Launch
//
//  Created by J. Howard Smart on 4/28/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RocketMotor.h"
#import "SLClusterMotor.h"

@protocol SLRocketPhysicsDatasource <NSObject>

- (float)thrustAtTime:(float)time;      // always metric - Newtons
- (float)massAtTime:(float)time;        // kilograms
- (float)cdAtTime:(float)time;          // for future use with staging rockets
- (float)areaAtTime:(float)time;        // meters^2
- (float)burnoutTime;
- (float)burnoutMass;
- (float)peakThrust;
- (float)maximumThrust;
//@property (nonatomic, readonly) NSArray *burnoutTimes;

@end

@interface Rocket : NSObject<NSCopying, NSSecureCoding, SLRocketPhysicsDatasource>

@property (nonatomic, strong, nullable) NSString * name;          //user's name for the rocket
@property (nonatomic) float length;        //meters float
@property (nonatomic) float diameter;      //meters float
@property (nonatomic) float cd;            //dimensionless float
@property (nonatomic) NSUInteger motorSize;     //this one is an integer number of millimeters (just the largest, central one - compatibility)
@property (nonatomic) float mass;          //kilograms float
@property (nonatomic) float massWithMotors;
@property (nonatomic, strong, nullable) NSString * kitName;       //manufacturer's name for the kit
@property (nonatomic, strong, nullable) NSString * manufacturer;  //company that made the kit (if any)
@property (nonatomic, strong, nullable) NSArray *recordedFlights; //array of NSDictionary* plists of flight information
@property (nonatomic, strong, nullable) NSArray *motorConfig;        //only available in v1.5 or later - may indicate single motor mount (default)
@property (nonatomic, readonly) float version;
@property (nonatomic, readonly, nullable) NSString *motorManufacturer;
@property (nonatomic, readonly, nullable) NSString *impulseClass;
@property (nonatomic, readonly, nullable) NSArray *motors;
@property (nonatomic, readonly, nullable) NSString *motorDescription;
@property (nonatomic, readonly) BOOL hasClusterMount;
@property (nonatomic, strong, readonly, nullable) NSArray *previousLoadOuts;
@property (nonatomic, strong, nonnull) NSString *avatar; //this corresponds to a named UIImage set in the asset catalog

-(NSDictionary * _Nonnull)rocketPropertyList;
-(NSArray * _Nullable)motorLoadoutPlist;
-(float)totalImpulse;

// methods to modify the motor cluster

-(void)replaceMotorForGroupAtIndex:(NSUInteger)index withMotor:(RocketMotor * _Nullable)motor andStartDelay:(float)delay;
-(void)changeDelayTo:(float)delay forMotorGroupAtIndex:(NSUInteger)index;
-(void)removeMotorGroupAtIndex:(NSUInteger)index;
/* this takes an array of NSDictionary * of the form {MOTOR_COUNT_KEY: int, MOTOR_PLIST_KEY: motorDict} one for each group */
-(void)replaceMotorLoadOutWithLoadOut:(NSArray * _Nullable)motorLoadOut;

+(Rocket * _Nullable)rocketWithRocketDict:(NSDictionary * _Nonnull)rocketDict;

// THIS is the designated initializer that the above class method uses to create a new Rocket*
-(Rocket * _Nullable)initWithProperties:(NSDictionary * _Nonnull)properties;
-(Rocket * _Nonnull)copy;
-(Rocket * _Nonnull)copyWithZone:(NSZone * _Nullable)zone;
-(void)addFlight:(NSDictionary * _Nonnull)flightData;
-(void)clearFlights;

// This is a convenience factory method that generates a Rocket * with generic properties
+(Rocket * _Nonnull)defaultRocket;

@end
