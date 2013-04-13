//
//  SLClusterMotor.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/12/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterMotor.h"

#define CLUSTER_MOTOR_KEY @"com.mySmartSoftware.clusterMotorKey"
#define CLUSTER_START_DELAY_KEY @"com.mySmartSoftware.clusterStartDelayKey"
#define DELAY_TOLERANCE 0.001

@interface SLClusterMotor()

@property (nonatomic, strong, readwrite) NSArray *motors;

@end

@implementation SLClusterMotor

-(NSArray *)motors{
    if (!_motors){
        _motors = [NSArray array];
    }
    return _motors;
}

-(void)addClusterMotor:(RocketMotor *)motor withStartDelay:(NSNumber *)delay{
    NSMutableArray *newMotors = [self.motors mutableCopy];
    NSDictionary *newMotorEntry = @{CLUSTER_MOTOR_KEY: [motor copy],
                                    CLUSTER_START_DELAY_KEY: delay};
    [newMotors addObject:newMotorEntry];
    self.motors = [newMotors copy];
}

-(BOOL)removeClusterMotor:(RocketMotor *)motor atStartDelay:(NSNumber *)delay{
    BOOL found = NO;
    NSMutableArray *newMotors = [self.motors mutableCopy];
    for (NSDictionary *clusterDict in self.motors) {
        RocketMotor *clusterMotor = clusterDict[CLUSTER_MOTOR_KEY];
        float startTime = [clusterDict[CLUSTER_START_DELAY_KEY] floatValue];
        if ([clusterMotor isEqual:motor] && (fabsf([delay floatValue] - startTime) < DELAY_TOLERANCE)){
            [newMotors removeObject:clusterDict];
            found = YES;
            self.motors = [newMotors copy];
            break;
        }
    }
    return found;
}

- (CGFloat)thrustAtTime:(CGFloat)time{
    float thrust = 0.0;
    for (NSDictionary *clusterDict in self.motors){
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
    for (NSDictionary *clusterDict in self.motors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        float startTime = [clusterDict[CLUSTER_START_DELAY_KEY] floatValue];
        if (time > startTime){
            mass += [motor massAtTime:(time - startTime)];
        }else{
            mass += [[motor loadedMass] floatValue];
        }
    }
    return mass;
}

#pragma mark - Override superclass methods

-(NSString *)impulseClass{
    return [RocketMotor impulseClassForTotalImpulse:self.totalImpulse];
}

-(NSNumber *)propellantMass{
    float totalMass = 0.0;
    for (NSDictionary *clusterDict in self.motors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        totalMass += [motor.propellantMass floatValue];
    }
    return @(totalMass);
}

-(NSNumber *)loadedMass{
    float totalMass = 0.0;
    for (NSDictionary *clusterDict in self.motors){
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
    for (NSDictionary *clusterDict in self.motors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        impulse += [[motor totalImpulse] floatValue];
    }
    return @(impulse);
}

-(NSString *)description{
    if (self.name) return self.name;
    return [NSString stringWithFormat:@"%d %@", [self.motors count], NSLocalizedString(@"motor cluster", @"Like '5 motor cluster'")];
}

-(NSString *)manufacturer{
    //the reason I am returning the manufacturer of the first motor is so that we can see a
    //manufacturer logo on screen (they are looked up based on this name)
    if ([self.motors count]){
        return [self.motors[0][CLUSTER_MOTOR_KEY] manufacturer];
    }
    return nil;
}

-(NSNumber *)length{
    float maxLength = 0.0;
    for (NSDictionary *clusterDict in self.motors){
        RocketMotor *motor = clusterDict[CLUSTER_MOTOR_KEY];
        if ([[motor length] floatValue] > maxLength)
            maxLength = [[motor length] floatValue];
    }
    return @(maxLength);
}

#pragma mark - Override and nil out methods which do not make sense for a cluster

-(NSDictionary *)motorDict{
    return nil;
}

-(NSNumber *)diameter{
    return nil;
}

-(NSArray *)delays{
    return nil;
}

-(void)dealloc{
    _motors = nil;
}

@end
