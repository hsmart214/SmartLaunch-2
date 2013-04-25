//
//  Rocket.m
//  Smart Launch
//
//  Created by J. Howard Smart on 4/28/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "Rocket.h"
#import "RocketMotor.h"

@interface Rocket()

@property (nonatomic, readwrite) float version;
@property (nonatomic, strong, readwrite) NSMutableArray *internalMotors;
@property (nonatomic) float *thrusts;
@property (nonatomic) NSUInteger thrustCount;

@end

@implementation Rocket

// motor array modification methods

-(void)adjustThrustData{
    if (_thrusts) free(_thrusts);
    int count = floor(self.burnoutTime * DIVS_DURING_BURN) + 1;
    self.thrustCount = count;
    self.thrusts = malloc(count * sizeof(float));
    for (int i = 0; i < count; i++){
        self.thrusts[i] = [self thrustAtTime:((float)i)/DIVS_DURING_BURN];
    }
}

-(NSMutableArray *)internalMotors{
    if (!_internalMotors){
        _internalMotors = [[NSMutableArray alloc] init];
    }
    return _internalMotors;
}
    
-(void)removeMotorGroupAtIndex:(NSUInteger)index{
    [self.internalMotors removeObjectAtIndex:index];
}

-(void)changeDelayTo:(float)delay forMotorGroupAtIndex:(NSUInteger)index{
    RocketMotor *motor = self.internalMotors[index];
    motor.startDelay = delay;
}

-(void)replaceMotorGroupAtIndex:(NSUInteger)index withMotor:(RocketMotor *)motor andStartDelay:(float)delay{
    motor = [motor copy];
    motor.startDelay = delay;
    [self.internalMotors replaceObjectAtIndex:index withObject:motor];
}

-(NSArray *)motors{
    return [self.internalMotors copy];
}

-(NSUInteger)motorSize{
    if ([self.motorConfig count]) return [self.motorConfig[0][MOTOR_DIAM_KEY] integerValue];
    return MOTOR_DEFAULT_DIAMETER;
}

//- (NSUInteger)minimumNumberOfMotors{
//    switch (self.motorConfig) {
//        case SLMotorConfigurationSingleMotor:
//        case SLMotorConfigurationInlineThree:
//        case SLMotorConfigurationThreeAroundOne:
//        case SLMotorConfigurationFourAroundOne:
//        case SLMotorConfigurationSixAroundOne:
//            return 1;
//        case SLMotorConfigurationDual:
//        case SLMotorConfigurationDiamond:
//        case SLMotorConfigurationHexagon:
//            return 2;
//        case SLMotorConfigurationTriangle:
//            return 3;
//        case SLMotorConfigurationPentagon:
//            return 5;
//    }
//}
//
//- (NSArray *)setsOfIdenticalMotorsNeeded{
//    // Thank goodness for modern Objective-C!
//    // I never would have done this this way if I had to write this out [NSArray arrayWithObjects:[NSNumber numberWithInt:]]
//    // Note that there is an outer array of possible configurations, each one of which
//    // is an array of numbers of motors which are required by geometry to be IDENTICAL
//    // Where's Python when you need it?
//    switch (self.motorConfig) {
//        case SLMotorConfigurationSingleMotor:
//            return @[@[@1]];
//        case SLMotorConfigurationDual:
//            return @[@[@2]];
//        case SLMotorConfigurationInlineThree:
//            return @[@[@1, @2]];
//        case SLMotorConfigurationTriangle:
//            return @[@[@3]];
//        case SLMotorConfigurationDiamond:
//            return @[@[@2, @2]];
//        case SLMotorConfigurationThreeAroundOne:
//            return @[@[@1, @3]];
//        case SLMotorConfigurationFourAroundOne:
//            return @[@[@1, @2, @2], @[@1, @4]];
//        case SLMotorConfigurationPentagon:
//            return @[@[@5]];
//        case SLMotorConfigurationHexagon:
//            return @[@[@2, @2, @2], @[@3, @3]];
//        case SLMotorConfigurationSixAroundOne:
//            return @[@[@1, @2, @2, @2], @[@1, @3, @3]];
//    }
//}

- (void)clearFlights{
    self.recordedFlights = nil;
}

- (void)addFlight:(NSDictionary *)flightData{
    NSMutableArray *newFlights = [self.recordedFlights mutableCopy];
    if (!newFlights) newFlights = [NSMutableArray array];
    [newFlights addObject:flightData];
    self.recordedFlights = [newFlights copy];
}

#pragma mark - SLRocketPhysicsDatasource methods

-(float)massAtTime:(float)time{
    float mass = 0.0;
    for (RocketMotor *motor in self.motors){
        mass += [motor massAtTime:time];
    }
    return mass;
}

-(float)burnoutMass{
    return [self massAtTime:self.burnoutTime];
}

-(float)thrustAtTime:(float)time{
    float thrust = 0.0;
    for (RocketMotor *motor in self.motors){
        thrust += [motor thrustAtTime:time];
    }
    return thrust;
}

-(float)burnoutTime{
    float time = 0.0;
    for (RocketMotor *motor in self.motors) {
        float t = [[motor.times lastObject] floatValue];
        if (t > time) time = t;
    }
    return time;
}

-(float)cdAtTime:(float)time{
    return self.cd;
}

-(float)areaAtTime:(float)time{
    return _PI_ * _diameter * _diameter / 4.0;
}

- (Rocket *)copyWithZone: (NSZone *)zone{
    return [Rocket rocketWithRocketDict:self.rocketPropertyList];
}

- (Rocket *)copy{
    return [self copyWithZone:nil];
}

- (float)cd{
    if (!_cd){
        _cd = DEFAULT_CD;
    }
    return _cd;
}

-(Rocket *)initWithProperties:(NSDictionary *)rocketProperties{
    self = [super init];
    self.version = [rocketProperties[SMART_LAUNCH_VERSION_KEY] floatValue];     // will return 0 if not v1.5+
    self.name = rocketProperties[ROCKET_NAME_KEY];
    self.length = [rocketProperties[ROCKET_LENGTH_KEY] floatValue];
    self.diameter = [rocketProperties[ROCKET_DIAM_KEY] floatValue];
    self.cd = [rocketProperties[ROCKET_CD_KEY] floatValue];
    self.motorSize = [rocketProperties[ROCKET_MOTORSIZE_KEY] integerValue];
    self.mass = [rocketProperties[ROCKET_MASS_KEY] floatValue];
    self.kitName = rocketProperties[ROCKET_KITNAME_KEY];
    self.manufacturer = rocketProperties[ROCKET_MAN_KEY];
    self.recordedFlights = rocketProperties[ROCKET_RECORDED_FLIGHTS_KEY];
    if (self.version >= 1.5){
        self.motorConfig = rocketProperties[ROCKET_MOTOR_CONFIG_KEY];
    }else{
        self.motorConfig = @[@{MOTOR_COUNT_KEY: @1,
                             MOTOR_DIAM_KEY: @(self.motorSize)}];
    }
    return self;
}

-(Rocket *)init{
    NSDictionary *rocketProperties = @{};
    self = [self initWithProperties:rocketProperties];
    return self;
}

- (void)dealloc{
    self.name = nil;
    self.kitName = nil;
    self.manufacturer = nil;
    self.recordedFlights = nil;
    self.motorConfig = nil;
    free(self.thrusts);
}

-(NSDictionary *)rocketPropertyList{
    NSMutableDictionary *rocketProperties = [NSMutableDictionary dictionary];
    if (self.name) rocketProperties[ROCKET_NAME_KEY] = self.name;
    if (self.length) rocketProperties[ROCKET_LENGTH_KEY] = @(self.length);
    if (self.diameter) rocketProperties[ROCKET_DIAM_KEY] = @(self.diameter);
    if (self.cd) rocketProperties[ROCKET_CD_KEY] = @(self.cd);
    if (self.motorSize) rocketProperties[ROCKET_MOTORSIZE_KEY] = @(self.motorSize);
    if (self.motorConfig) rocketProperties[ROCKET_MOTOR_CONFIG_KEY] = self.motorConfig;
    if (self.mass) rocketProperties[ROCKET_MASS_KEY] = @(self.mass);
    if (self.kitName) rocketProperties[ROCKET_KITNAME_KEY] = self.kitName;
    if (self.manufacturer) rocketProperties[ROCKET_MAN_KEY] = self.manufacturer;
    if (self.recordedFlights) rocketProperties[ROCKET_RECORDED_FLIGHTS_KEY] = self.recordedFlights;
    rocketProperties[SMART_LAUNCH_VERSION_KEY] = @(SMART_LAUNCH_VERSION);   // always save under the current version
    return rocketProperties;
}

+(Rocket *)rocketWithRocketDict:(NSDictionary *)rocketDict{
    Rocket *rocket = [[Rocket alloc] initWithProperties:rocketDict];
    return rocket;
}

+(Rocket *)defaultRocket{
    NSDictionary *goblinProperties = @{ROCKET_NAME_KEY: @"Goblin",
                                      ROCKET_KITNAME_KEY: @"Goblin",
                                      ROCKET_MAN_KEY: @"Estes",
                                      ROCKET_DIAM_KEY: @0.033655f,
                                      ROCKET_LENGTH_KEY: @0.36322f,
                                      ROCKET_MASS_KEY: @0.034f,
                                      ROCKET_MOTORSIZE_KEY: @24,
                                      ROCKET_CD_KEY: @(DEFAULT_CD),
                                      ROCKET_MOTOR_CONFIG_KEY: @[@{MOTOR_DIAM_KEY: @24,
                                                                MOTOR_COUNT_KEY: @1}],
                                      SMART_LAUNCH_VERSION_KEY: @(SMART_LAUNCH_VERSION)};

    return [[Rocket alloc] initWithProperties:goblinProperties];
}

-(NSString *)description{
    return [NSString stringWithFormat:@"Rocket: %@", self.name];
}
@end
