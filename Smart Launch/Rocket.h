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

@interface Rocket : NSObject<NSCopying, SLRocketPhysicsDatasource>

@property (nonatomic, strong) NSString * name;          //user's name for the rocket
@property (nonatomic) float length;        //meters float
@property (nonatomic) float diameter;      //meters float
@property (nonatomic) float cd;            //dimensionless float
@property (nonatomic) NSUInteger motorSize;     //this one is an integer number of millimeters (just the largest, central one - compatibility)
@property (nonatomic) float mass;          //kilograms float
@property (nonatomic) float massWithMotors;
@property (nonatomic, strong) NSString * kitName;       //manufacturer's name for the kit
@property (nonatomic, strong) NSString * manufacturer;  //company that made the kit (if any)
@property (nonatomic, strong) NSArray *recordedFlights; //array of NSDictionary* plists of flight information
@property (nonatomic, strong) NSArray *motorConfig;        //only available in v1.5 or later - may indicate single motor mount (default)
@property (nonatomic, readonly) float version;
@property (nonatomic, readonly) NSString *motorManufacturer;
@property (nonatomic, readonly) NSString *impulseClass;
@property (nonatomic, readonly) NSArray *motors;
@property (nonatomic, readonly) NSString *motorDescription;
@property (nonatomic, readonly) BOOL hasClusterMount;
@property (nonatomic, strong, readonly) NSArray *previousLoadOuts;

-(NSDictionary *)rocketPropertyList;
-(NSArray *)motorLoadoutPlist;
-(float)totalImpulse;

// methods to modify the motor cluster

-(void)replaceMotorForGroupAtIndex:(NSUInteger)index withMotor:(RocketMotor *)motor andStartDelay:(float)delay;
-(void)changeDelayTo:(float)delay forMotorGroupAtIndex:(NSUInteger)index;
-(void)removeMotorGroupAtIndex:(NSUInteger)index;
/* this takes an array of NSDictionary * of the form {MOTOR_COUNT_KEY: int, MOTOR_PLIST_KEY: motorDict} one for each group */
-(void)replaceMotorLoadOutWithLoadOut:(NSArray *)motorLoadOut;

+(Rocket *)rocketWithRocketDict:(NSDictionary *)rocketDict;

// THIS is the designated initializer that the above class method uses to create a new Rocket*
-(Rocket *)initWithProperties:(NSDictionary *)properties;
-(Rocket *)copy;
-(Rocket *)copyWithZone:(NSZone *)zone;
-(void)addFlight:(NSDictionary *)flightData;
-(void)clearFlights;

// This is a convenience factory method that generates a Rocket * with generic properties
+(Rocket *)defaultRocket;

@end
