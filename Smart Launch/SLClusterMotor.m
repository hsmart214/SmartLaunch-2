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

-(NSString *)firstMotorName{
    if (![self.motors count]) return nil;
    RocketMotor *motor = self.motors[0];
    return motor.name;
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
        disp = [NSString stringWithFormat:@"%d %@", count, motorDict[NAME_KEY]];
        if (count > 1) disp = [disp stringByAppendingString:@"'s"];
    }
    if ([self.motorLoadout count] > 1){
        for (int i = 1; i < [self.motorLoadout count]; i++) {
            NSDictionary *dict = self.motorLoadout[i];
            NSUInteger count = [dict[MOTOR_COUNT_KEY] integerValue];
            NSDictionary *motorDict = dict[MOTOR_PLIST_KEY];
            disp = [disp stringByAppendingString:[NSString stringWithFormat:@", %d %@'s", count, motorDict[NAME_KEY]]];
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
            descr = [NSString stringWithFormat:@"%d %@", [dict[MOTOR_COUNT_KEY] integerValue], motorDict[NAME_KEY]];
            if ([dict[MOTOR_COUNT_KEY] integerValue] > 1) descr = [descr stringByAppendingString:@"'s"];
        }else{
            descr = [descr stringByAppendingString:[NSString stringWithFormat:@", %d %@'s", [dict[MOTOR_COUNT_KEY] integerValue], motorDict[NAME_KEY]]];
        }
    }
    return descr;
}



// this is the actual designated intializer

-(id)initWithMotorLoadout:(NSArray *)motorLoadout{
    if (self){
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

-(id)copyWithZone:(NSZone *)zone{
    return [self copy];
}

-(id)copy{
    return self;
}

-(void)dealloc{
    _motors = nil;
}

@end
