//
//  SLClusterMotor.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/12/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterMotor.h"
#import "RocketMotor.h"


@interface SLClusterMotor()

@property (nonatomic, strong) NSArray *motorLoadout;
@property (nonatomic, strong) NSMutableArray *motors;    // array of RocketMotor * with startDelays
@property (nonatomic, strong) NSString *fractionalImpulseDisplay;

@end

@implementation SLClusterMotor

+(double)totalImpulseFromFlight:(NSDictionary *)flight{
    SLClusterMotor *cMotor;
    // find out if the saved record is an old one - pre-clusters
    // the settings has a complete motorPlist stashed away in it in SELECTED_MOTOR_KEY
    // if the version is 1.5 or higher, this will be an NSArray rather than a motorDict
    // versions 1.4 and previous did not have a SMART_LAUNCH_VERSION_KEY key at all, so it will be nil
    if (flight[SMART_LAUNCH_VERSION_KEY]){
        NSDictionary *settings = flight[FLIGHT_SETTINGS_KEY];
        cMotor = [[SLClusterMotor alloc] initWithMotorLoadout:settings[SELECTED_MOTOR_KEY]];
    }else if (flight[MOTOR_PLIST_KEY]){
        cMotor = [[SLClusterMotor alloc] initWithMotorLoadout:flight[MOTOR_PLIST_KEY]];
    }else{
        return [RocketMotor totalImpulseOfMotorWithName:flight[FLIGHT_MOTOR_KEY]];
    }
    
    return cMotor.totalImpulse;
}

-(NSString *)firstMotorName{
    if (![self.motors count]) return nil;
    RocketMotor *motor = self.motors[0];
    return motor.name;
}

-(NSString *)firstMotorManufacturer{
    if (![self.motors count]) return nil;
    RocketMotor *motor = self.motors[0];
    return motor.manufacturer;
}

-(NSUInteger)motorCount{
    return [self.motors count];
}

-(NSMutableArray *)motors{
    if (!_motors){
        _motors = [NSMutableArray array];
    }
    return _motors;
}

-(float)propellantMass{
    float totalMass = 0.0;
    for (RocketMotor *motor in self.motors){
        totalMass += motor.propellantMass;
    }
    return totalMass;
}

-(float)mass{
    float totalMass = 0.0;
    for (RocketMotor *motor in self.motors){
        totalMass += motor.loadedMass;
    }
    return totalMass;
}

-(NSUInteger)diameter{
    // returns the diameter of the first group
    NSUInteger diam = 0;
    if ([self.motors count]) diam = [self.motors[0] diameter];
    return diam;
}

-(float)totalImpulse{
    float impulse = 0.0;
    for (RocketMotor *motor in self.motors){
        impulse += motor.totalImpulse;
    }
    return impulse;
}

-(float)totalBurnLength{
    float burntime = 0.0;
    for (RocketMotor *motor in self.motors) {
        if (motor.burnoutTime > burntime) burntime = motor.burnoutTime;
    }
    return burntime;
}

-(float)thrustAtTime:(float)time{
    float thrust = 0.0;
    for (RocketMotor *motor in self.motors){
        thrust += [motor thrustAtTime:time];
    }
    return thrust;
}

-(float)peakInitialThrust{
    float thrust, oldThrust, time;
    time = 1.0/DIVS_DURING_BURN;
    thrust = [self thrustAtTime:time];
    oldThrust = thrust;
    while (thrust >= oldThrust) {
        time += 1.0/DIVS_DURING_BURN;
        oldThrust = thrust;
        thrust = [self thrustAtTime:time];
    }
    return oldThrust;
}

-(float)truePeakThrust{
    float thrust, peakThrust, time, brnoutime;
    time = 1.0/DIVS_FOR_RAPID_CALC;
    thrust = [self thrustAtTime:time];
    peakThrust = thrust;
    brnoutime = self.totalBurnLength;
    while (time < brnoutime) {
        time += 1.0/DIVS_FOR_RAPID_CALC;
        if (thrust > peakThrust) peakThrust = thrust;
        thrust = [self thrustAtTime:time];
    }
    return peakThrust;
}

-(NSString *)impulseClass{
    return [RocketMotor impulseClassForTotalImpulse:self.totalImpulse];
}

-(float)fractionOfImpulseClass{
    int classIndex = 0;
    float impulse = self.totalImpulse;
    if (impulse < [[RocketMotor impulseLimits][classIndex] floatValue]) return impulse/[[RocketMotor impulseLimits][classIndex] floatValue];
    while (impulse > [[RocketMotor impulseLimits][classIndex] floatValue]) {
        classIndex++;
        if (classIndex == [[RocketMotor impulseClasses] count]) return 1.0;  // protects against overflow
    }   //now the classIndex points to the class ABOVE our class
    float prevLimit = [[RocketMotor impulseLimits][classIndex-1] floatValue];
    return (impulse - prevLimit)/prevLimit;   // this won't underflow because of the third line
}


-(NSString *)fractionalImpulseClass{
    
    if (!_fractionalImpulseDisplay){
        _fractionalImpulseDisplay = [NSString stringWithFormat:@"%1.0f%% %@", [self fractionOfImpulseClass] * 100, self.impulseClass];
    }
    return self.fractionalImpulseDisplay;
}

-(NSString *)longDescription{
    NSString *disp = @"";
    if ([self.motorLoadout count]){
        NSDictionary *dict = self.motorLoadout[0];
        NSUInteger count = [dict[MOTOR_COUNT_KEY] integerValue];
        NSDictionary *motorDict = dict[MOTOR_PLIST_KEY];
        disp = [NSString stringWithFormat:@"%lu %@", (unsigned long)count, motorDict[NAME_KEY]];
        if (count > 1) disp = [disp stringByAppendingString:@"'s"];
    }
    if ([self.motorLoadout count] > 1){
        for (int i = 1; i < [self.motorLoadout count]; i++) {
            NSDictionary *dict = self.motorLoadout[i];
            NSUInteger count = [dict[MOTOR_COUNT_KEY] integerValue];
            NSDictionary *motorDict = dict[MOTOR_PLIST_KEY];
            disp = [disp stringByAppendingString:[NSString stringWithFormat:@", %lu %@'s", (unsigned long)count, motorDict[NAME_KEY]]];
        }
    }
    return disp;
}

-(NSString *)description{
    if (!self.motorCount) return @"No Motors";
    NSString *descr;
    for (NSDictionary *dict in self.motorLoadout) {
        NSDictionary *motorDict = dict[MOTOR_PLIST_KEY];
        if (!descr){
            descr = [NSString stringWithFormat:@"%ld %@", (long)[dict[MOTOR_COUNT_KEY] integerValue], motorDict[NAME_KEY]];
            if ([dict[MOTOR_COUNT_KEY] integerValue] > 1) descr = [descr stringByAppendingString:@"'s"];
        }else{
            descr = [descr stringByAppendingString:[NSString stringWithFormat:@", %ld %@'s", (long)[dict[MOTOR_COUNT_KEY] integerValue], motorDict[NAME_KEY]]];
        }
    }
    return descr;
}



// this is the actual designated intializer

-(instancetype)initWithMotorLoadout:(id)motorLoadout{
    if (self){
        if ([motorLoadout isKindOfClass:[NSDictionary class]]){
            motorLoadout = @[@{MOTOR_PLIST_KEY : motorLoadout,
                             MOTOR_COUNT_KEY : @1}];
        }
        self.motorLoadout = motorLoadout;
        for (NSDictionary *motorGroup in motorLoadout){
            NSDictionary *motorDict = motorGroup[MOTOR_PLIST_KEY];
            NSUInteger count = [motorGroup[MOTOR_COUNT_KEY] integerValue];
            RocketMotor *motor = [RocketMotor motorWithMotorDict:motorDict];
            for (int i = 0; i < count; i++){
                [self.motors addObject:motor];
            }
        }
    }
    return self;
}

-(instancetype)copyWithZone:(NSZone *)zone{
    return [self copy];
}

-(instancetype)copy{
    return self;
}

-(void)dealloc{
    _motors = nil;
}

@end
