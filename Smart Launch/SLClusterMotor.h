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
//Each motor can have a delayed ignition which can be an offset from ignition or burnout of a previous motor.
//Thus we store an array of dictionaries, each has a RocketMotor and an NSNumber start delay in seconds (from zero).

@interface SLClusterMotor : RocketMotor

@property (nonatomic, strong, readonly) NSArray *motors;  //array of NSDictionary
@property (nonatomic, strong, readwrite) NSString *name;  //for this subclass I need to allow the name to be changed

-(void)addClusterMotor:(RocketMotor *)motor withStartDelay:(NSNumber *)delay;
//the next method removes the first motor in the array which "isEqual" to the passed in motor, AND whose start time
//is within a tolerance of the passed in start delay
-(BOOL)removeClusterMotor:(RocketMotor *)motor atStartDelay:(NSNumber *)delay;  //the return value indicates success

@end
