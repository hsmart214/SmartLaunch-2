//
//  SLClusterMotor.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/12/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterMotor.h"


@interface SLClusterMotor()

@property (nonatomic, strong) NSMutableArray *privateMotors;    // array of RocketMotor * with startDelays (copies of motors added)

@end

@implementation SLClusterMotor

-(NSArray *)motors{
    return [self.privateMotors copy];
}

-(NSMutableArray *)privateMotors{
    if (!_privateMotors){
        _privateMotors = [NSMutableArray array];
    }
    return _privateMotors;
}

-(void)addMotor:(RocketMotor *)motor withStartDelay:(float)delay{
    RocketMotor *newMotorEntry = [motor copy];
    newMotorEntry.startDelay = delay;
    [self.privateMotors addObject:newMotorEntry];
}

-(void)replaceMotorAtIndex:(NSUInteger)index withMotor:(RocketMotor *)motor andStartDelay:(float)delay{
    RocketMotor *newMotor = [motor copy];
    newMotor.startDelay = delay;
    self.privateMotors[index] = newMotor;
}

-(void)removeClusterMotorAtIndex:(NSUInteger)index{
    if ([self.privateMotors count]-1 < index) return;
    [self.privateMotors removeObjectAtIndex:index];
}

-(void)changeDelayTo:(float)delay forMotorAtIndex:(NSUInteger)index{
    RocketMotor *motor = self.privateMotors[index];
    motor.startDelay = delay;
}

-(float)timeToFirstBurnout{
    float time = 0.0;
    float burnout = self.totalBurnLength;
    while (time < burnout) {
        time += 0.02;
        if ([self thrustAtTime:time]) break;
    }
    return time;
}

#pragma mark - Override superclass methods

-(NSString *)impulseClass{
    return [RocketMotor impulseClassForTotalImpulse:self.totalImpulse];
}

-(float)propellantMass{
    float totalMass = 0.0;
    for (NSDictionary *clusterDict in self.privateMotors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        totalMass += motor.propellantMass;
    }
    return totalMass;
}

-(float)loadedMass{
    float totalMass = 0.0;
    for (NSDictionary *clusterDict in self.privateMotors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        totalMass += motor.loadedMass;
    }
    return totalMass;
}

-(float)peakThrust{
#define TIME_STOP 0.5
#define TIME_SLICE 0.002
    //I am going to run a little coarsely through the first 500 msec of thrust to find the peak of the combined thrust.
    float peak = 0.0;
    float timeIndex = 0.0;
    while (timeIndex < TIME_STOP) {
        float thrust = [self thrustAtTime:timeIndex];
        if (thrust > peak){
            peak = thrust;
            timeIndex += TIME_SLICE;
        }else{
            break;
        }
    }
    return peak;
}

-(float)totalImpulse{
    float impulse = 0.0;
    for (NSDictionary *clusterDict in self.privateMotors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        impulse += motor.totalImpulse;
    }
    return impulse;
}

-(NSString *)description{
    if (self.name) return self.name;
    return [NSString stringWithFormat:@"%d %@", [self.privateMotors count], NSLocalizedString(@"motor cluster", @"Like '5 motor cluster'")];
}

-(NSString *)manufacturer{
    //the reason I am returning the manufacturer of the first motor is so that we can see a
    //manufacturer logo on screen (they are looked up based on this name)
    if ([self.privateMotors count]){
        return [self.privateMotors[0][CLUSTER_MOTOR_KEY] manufacturer];
    }
    return nil;
}

-(float)length{
    float maxLength = 0.0;
    for (NSDictionary *clusterDict in self.privateMotors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        if (motor.length > maxLength)
            maxLength = motor.length;
    }
    return maxLength;
}

-(NSArray *)clusterPlistArray{
    //this for saving in the user defaults and iCloud
    NSMutableArray *array = [NSMutableArray array];
    for (RocketMotor *motor in self.privateMotors){
        NSDictionary *motorDict = [motor motorDict];
        [array addObject:motorDict];
    }
    return [array copy];
}

// this is the actual designated intializer

-(SLClusterMotor *)initWithMotorDictArray:(NSArray *)motorDictArray{
    if (self){
        for (NSDictionary *motorDict in motorDictArray){
            RocketMotor *motor = [RocketMotor motorWithMotorDict:motorDict];
            [self.privateMotors addObject:motor];
        }
    }
    return self;
}

+(SLClusterMotor *)clusterMotorWithMotorDictArray:(NSArray *)motorDictArray{
    if (!motorDictArray) return nil;
    SLClusterMotor *motor = [[SLClusterMotor alloc] initWithMotorDictArray:motorDictArray];
    return motor;
}

+(SLClusterMotor *)clusterMotorWithRocketMotorArray:(NSArray *)motorArray{
    NSMutableArray *motorDicts = [NSMutableArray array];
    for (RocketMotor *motor in motorArray) {
        [motorDicts addObject:[motor motorDict]];
    }
    return [[SLClusterMotor alloc] initWithMotorDictArray:motorDicts];
}

+(SLClusterMotor *)clusterMotorWithRocketMotor:(RocketMotor *)motor{
    // creates and returns a new SLClusterMotor with a single motor and zero start delay (as all single motors must have)
    if (![motor isKindOfClass:[RocketMotor class]]) return nil;     //notice that this also accounts for a nil motor passed in
    motor.startDelay = 0.0;
    return [[SLClusterMotor alloc] initWithMotorDictArray:@[[motor motorDict]]];
}

+(SLClusterMotor *)defaultMotor{
    return [[SLClusterMotor alloc] initWithMotorDictArray:@[[[RocketMotor defaultMotor] motorDict]]];
}

#pragma mark - Override and nil out methods which do not make sense for a cluster

-(NSDictionary *)motorDict{ // replaced by the method clusterArray
    return nil;
}

-(NSUInteger)diameter{
    return 0;
}

-(NSArray *)delays{
    return nil;
}

-(void)dealloc{
    _privateMotors = nil;
}

@end
