//
//  SLClusterMotor.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/12/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterMotor.h"


@interface SLClusterMotor()

@property (nonatomic, strong) NSMutableArray *privateMotors;

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

-(void)addClusterMotor:(RocketMotor *)motor withStartDelay:(NSNumber *)delay{
    NSDictionary *newMotorEntry = @{CLUSTER_MOTOR_KEY: motor,
                                    CLUSTER_START_DELAY_KEY: delay};
    [self.privateMotors addObject:newMotorEntry];
}

-(void)replaceMotorAtIndex:(NSUInteger)index withMotor:(RocketMotor *)motor{
    NSMutableDictionary *dict = [self.motors[index] mutableCopy];
    dict[CLUSTER_MOTOR_KEY] = [motor copy];
    self.privateMotors[index] = [dict copy];
}

-(void)removeClusterMotorAtIndex:(NSUInteger)index{
    [self.privateMotors removeObjectAtIndex:index];
}

-(void)changeDelayTo:(float)delay forMotorAtIndex:(NSUInteger)index{
    NSMutableDictionary *dict = [self.privateMotors[index] mutableCopy];
    dict[CLUSTER_START_DELAY_KEY] = @(delay);
    self.privateMotors[index] = [dict copy];
}

- (CGFloat)thrustAtTime:(CGFloat)time{
    float thrust = 0.0;
    for (NSDictionary *clusterDict in self.privateMotors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        float startTime = [clusterDict[CLUSTER_START_DELAY_KEY] floatValue];
        if (time > startTime){
            thrust += [motor thrustAtTime:(time - startTime)];
        }
    }
    return thrust;
}

- (CGFloat)massAtTime:(CGFloat)time{
    float mass = 0.0;
    for (NSDictionary *clusterDict in self.privateMotors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        float startTime = [clusterDict[CLUSTER_START_DELAY_KEY] floatValue];
        if (time > startTime){
            mass += [motor massAtTime:(time - startTime)];
        }else{
            mass += [motor.loadedMass floatValue];
        }
    }
    return mass;
}

-(float)totalBurnLength{
    float burn = 0.0;
    for (NSDictionary *dict in self.motors){
        RocketMotor *motor = dict[CLUSTER_MOTOR_KEY];
        float start = [dict[CLUSTER_START_DELAY_KEY] floatValue];
        burn += start + [[motor.times lastObject] floatValue];
    }
    return burn;
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

-(NSNumber *)propellantMass{
    float totalMass = 0.0;
    for (NSDictionary *clusterDict in self.privateMotors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        totalMass += [motor.propellantMass floatValue];
    }
    return @(totalMass);
}

-(NSNumber *)loadedMass{
    float totalMass = 0.0;
    for (NSDictionary *clusterDict in self.privateMotors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        totalMass += [motor.loadedMass floatValue];
    }
    return @(totalMass);
}

-(NSNumber *)peakThrust{
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
    return @(peak);
}

-(NSNumber *)totalImpulse{
    float impulse = 0.0;
    for (NSDictionary *clusterDict in self.privateMotors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        impulse += [motor.totalImpulse floatValue];
    }
    return @(impulse);
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

-(NSNumber *)length{
    float maxLength = 0.0;
    for (NSDictionary *clusterDict in self.privateMotors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        if ([[motor length] floatValue] > maxLength)
            maxLength = [[motor length] floatValue];
    }
    return @(maxLength);
}

-(NSArray *)clusterArray{
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dict in self.privateMotors){
        NSDictionary *plist = @{CLUSTER_MOTORDICT_KEY: [dict[CLUSTER_MOTOR_KEY]motorDict],
                                CLUSTER_START_DELAY_KEY: dict[CLUSTER_START_DELAY_KEY]};
        [array addObject:plist];
    }
    return [array copy];
}

-(SLClusterMotor *)initWithClusterArray:(NSArray *)clusterArray{
    if (self){
        for (NSDictionary *dict in clusterArray){
            NSDictionary *motorDict = dict[CLUSTER_MOTORDICT_KEY];
            RocketMotor *motor = [RocketMotor motorWithMotorDict:motorDict];
            NSNumber *delay = dict[CLUSTER_START_DELAY_KEY];
            [self.privateMotors addObject:@{CLUSTER_MOTOR_KEY: motor,
                                      CLUSTER_START_DELAY_KEY: delay}];
        }
    }
    return self;
}

+(SLClusterMotor *)clusterMotorWithClusterArray:(NSArray *)clusterArray{
    if (!clusterArray) return nil;
    SLClusterMotor *motor = [[SLClusterMotor alloc] initWithClusterArray:clusterArray];
    return motor;
}

+(SLClusterMotor *)defaultMotor{
    NSDictionary *dict = @{CLUSTER_MOTORDICT_KEY: [[RocketMotor defaultMotor] motorDict],
                           CLUSTER_START_DELAY_KEY: @0.0};
    return [SLClusterMotor clusterMotorWithClusterArray:@[dict]];
}

#pragma mark - Override and nil out methods which do not make sense for a cluster

-(NSDictionary *)motorDict{ // replaced by the method clusterArray
    return nil;
}

-(NSNumber *)diameter{
    return nil;
}

-(NSArray *)delays{
    return nil;
}

-(void)dealloc{
    _privateMotors = nil;
}

@end
