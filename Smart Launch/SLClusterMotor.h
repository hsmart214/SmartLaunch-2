//
//  SLClusterMotor.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/12/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "RocketMotor.h"

//This subclass of RocketMotor will represent a cluster of RocketMotors as a single thrust source for the physics model.
//Any number of motors can be added and we will trust the rocketeer to make sure they are balanced.
//Each motor can have a delayed ignition which will be stored as an offset from ignition of the first motor.
//Thus we store an array of dictionaries, each has a RocketMotor and an NSNumber start delay in seconds.

@interface SLClusterMotor : RocketMotor

@property (nonatomic, strong, readonly) NSArray *motors;  //array of NSDictionary
@property (nonatomic, strong, readwrite) NSString *name;  //for this subclass I need to allow the name to be changed
@property (readonly) float totalBurnLength;
@property (readonly) float timeToFirstBurnout;

-(void)addMotor:(RocketMotor *)motor withStartDelay:(float)delay;
-(void)replaceMotorAtIndex:(NSUInteger)index withMotor:(RocketMotor *)motor andStartDelay:(float)delay;
-(void)changeDelayTo:(float)delay forMotorAtIndex:(NSUInteger)index;
-(void)removeClusterMotorAtIndex:(NSUInteger)index;

-(NSArray *)clusterPlistArray;

+(SLClusterMotor *)clusterMotorWithMotorDictArray:(NSArray *)motorDictArray;        // this is specifically to restore from iCloud/userdefaults
+(SLClusterMotor *)clusterMotorWithRocketMotorArray:(NSArray *)motorArray;          // this one assumes that the motors already have startDelays set
+(SLClusterMotor *)clusterMotorWithRocketMotor:(RocketMotor *)motor;                // convenience method to make a cluster out of a single motor

@end
