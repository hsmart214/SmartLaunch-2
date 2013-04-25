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
//Thus we store an array of RocketMotor * and each RocketMotor has a float property startDelay in seconds.

@interface SLClusterMotor : RocketMotor

@property (nonatomic, readonly) NSArray *motors;            //array of RocketMotor *
@property (nonatomic, strong, readwrite) NSString *name;    //for this subclass I need to allow the name to be changed
@property (readonly) float totalBurnLength;
@property (readonly) float timeToFirstBurnout;

-(NSArray *)clusterPlistArray;

-(void)replaceClusterMotorsWithMotors:(NSArray *)motors;    // takes an array of RocketMotor * with the startDelays already set

+(SLClusterMotor *)clusterMotorWithMotorDictArray:(NSArray *)motorDictArray;        // this is specifically to restore from iCloud/userdefaults
+(SLClusterMotor *)clusterMotorWithRocketMotorArray:(NSArray *)motorArray;          // this one assumes that the motors already have startDelays set
+(SLClusterMotor *)clusterMotorWithRocketMotor:(RocketMotor *)motor;                // convenience method to make a cluster out of a single motor

@end
