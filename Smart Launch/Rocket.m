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
@property (nonatomic, strong, readwrite) NSMutableArray *internalMotors;    // array of RocketMotor *
@property (nonatomic, strong) NSMutableArray *internalMotorsByGroup;        // array of NSArray *s of RocketMotor *, one array per group
//@property (nonatomic) float *thrusts;
//@property (nonatomic) NSUInteger thrustCount;
//@property (nonatomic, strong, readwrite) NSArray *burnoutTimes;

@end

@implementation Rocket

@synthesize previousLoadOuts = _previousLoadOuts;

float burrnoutTime, burrnoutMass;

// motor array modification methods

//-(void)adjustThrustData{
//    if (_thrusts) free(_thrusts);
//    int count = floor(self.burnoutTime * DIVS_DURING_BURN) + 1;
//    self.thrustCount = count;
//    self.thrusts = malloc(count * sizeof(float));
//    for (int i = 0; i < count; i++){
//        self.thrusts[i] = [self thrustAtTime:((float)i)/DIVS_DURING_BURN];
//    }
//}

-(NSMutableArray *)internalMotors{
    if (!_internalMotors){
        _internalMotors = [[NSMutableArray alloc] init];
    }
    return _internalMotors;
}

-(NSMutableArray *)internalMotorsByGroup{
    if (!_internalMotorsByGroup){
        _internalMotorsByGroup = [[NSMutableArray alloc] init];
    }
    return _internalMotorsByGroup;
}

-(NSArray *)motorLoadoutPlist{
    NSMutableArray *groups = [[NSMutableArray alloc] init];
    for (NSArray *group in self.internalMotorsByGroup) {
        if (![group count]) {
            [groups addObject:@{}];
        }else{
            NSDictionary *dict = @{MOTOR_COUNT_KEY: @([group count]),
                                   MOTOR_PLIST_KEY: [group[0] motorDict]};
            [groups addObject:dict];
        }
    }
    return [groups copy];;
}

-(void)updateMotorsFromGroups{
    [self.internalMotors removeAllObjects];
    for (NSArray *group in self.internalMotorsByGroup) {
        [self.internalMotors addObjectsFromArray:group];
    }
    burrnoutTime = 0.0;
    burrnoutMass = 0.0;
}
    
-(void)removeMotorGroupAtIndex:(NSUInteger)index{
    [self.internalMotorsByGroup replaceObjectAtIndex:index withObject:@[]];
    [self updateMotorsFromGroups];
}

-(void)changeDelayTo:(float)delay forMotorGroupAtIndex:(NSUInteger)index{
    NSArray *group = self.internalMotorsByGroup[index];
    if (![group count]) return;
    [group enumerateObjectsUsingBlock:^(RocketMotor *motor, NSUInteger idx, BOOL *stop){
        motor.startDelay = delay;
    }];
    [self updateMotorsFromGroups];
}

-(void)replaceMotorForGroupAtIndex:(NSUInteger)index withMotor:(RocketMotor *)motor andStartDelay:(float)delay{
    RocketMotor *thisMotor = [motor copy];
    thisMotor.startDelay = delay;
    NSArray *group = self.internalMotorsByGroup[index];
    int count = [group count];
    NSMutableArray *build = [[NSMutableArray alloc] init];
    for (int i = 0; i < count; i++){
        [build addObject:thisMotor];
    }
    [self.internalMotorsByGroup replaceObjectAtIndex:index withObject:[build copy]];
    [self updateMotorsFromGroups];
}

-(void)replaceMotorLoadOutWithLoadOut:(NSArray *)motorLoadOut{
    [self.internalMotorsByGroup removeAllObjects];
    for (NSDictionary *groupDict in motorLoadOut) {
        if ([groupDict count]){
            int count = [groupDict[MOTOR_COUNT_KEY] integerValue];
            NSMutableArray *build = [[NSMutableArray alloc] init];
            for (int i = 0; i < count; i++){
                NSDictionary *motorDict = groupDict[MOTOR_PLIST_KEY];
                [build addObject:[RocketMotor motorWithMotorDict:motorDict]];
            }
            [self.internalMotorsByGroup addObject:[build copy]];
        }else{
            [self.internalMotorsByGroup addObject:@[]];
        }
    }
    [self updateMotorsFromGroups];
}

-(NSArray *)previousLoadOuts{
    // cache the result
    if (!_previousLoadOuts){
        NSMutableArray *arr = [NSMutableArray array];
        for (NSDictionary *flightDict in self.recordedFlights) {
            id motorObject = flightDict[FLIGHT_SETTINGS_KEY][SELECTED_MOTOR_KEY];
            if ([motorObject isKindOfClass:[NSDictionary class]]){
                // It is a single motor
                [arr addObject:@[@{MOTOR_COUNT_KEY: @1,
                                   MOTOR_PLIST_KEY: motorObject}]];
            }else if([motorObject isKindOfClass:[NSArray class]]){
                // It is a cluster plist array
                [arr addObject:motorObject];
            }
        }
        _previousLoadOuts = [arr copy];
    }
    return _previousLoadOuts;
}

-(NSArray *)motors{
    return [self.internalMotors copy];
}

-(NSUInteger)motorSize{
    if ([self.motorConfig count]) return [self.motorConfig[0][MOTOR_DIAM_KEY] integerValue];
    return MOTOR_DEFAULT_DIAMETER;
}

-(BOOL)hasClusterMount{
    if (!_motorConfig) return NO;
    return ([self.motorConfig count] > 1 || [self.motorConfig[0][MOTOR_COUNT_KEY] integerValue] > 1);
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
    _previousLoadOuts = nil;
}

- (void)addFlight:(NSDictionary *)flightData{
    NSMutableArray *newFlights = [self.recordedFlights mutableCopy];
    if (!newFlights) newFlights = [NSMutableArray array];
    [newFlights addObject:flightData];
    self.recordedFlights = [newFlights copy];
    _previousLoadOuts = nil;                    // this will force it to be recalculated lazily
}

#pragma mark - SLRocketPhysicsDatasource methods

-(NSString *)impulseClass{
    return [RocketMotor impulseClassForTotalImpulse:self.totalImpulse];
}

-(float)propellantMass{
    float totalMass = 0.0;
    for (RocketMotor *motor in self.internalMotors){
        totalMass += motor.propellantMass;
    }
    return totalMass;
}

-(float)loadedMass{
    float totalMass = 0.0;
    for (RocketMotor *motor in self.internalMotors){
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
        if (thrust >= peak){
            peak = thrust;
            timeIndex += TIME_SLICE;
        }else{
            break;
        }
    }
    return peak;
}

-(float)maximumThrust{
    //this time we run through the entire thrust curve, but a little more coarsely
#undef TIME_SLICE
#define TIME_SLICE 0.01
    float peak = 0.0;
    float timeIndex = 0.0;
    while (timeIndex < [self burnoutTime]) {
        float thrust = [self thrustAtTime:timeIndex];
        if (thrust >= peak){
            peak = thrust;
        }
        timeIndex += TIME_SLICE;
    }
    return peak;
}

-(NSString *)motorDescription{
    if (![self.internalMotors count]) return NSLocalizedString(@"No Motor Selected", @"No motor selected");
    if ([self.internalMotors count] == 1) return [self.internalMotors[0] description];
    return [NSString stringWithFormat:@"%d %@", [self.internalMotors count], NSLocalizedString(@"motor cluster", @"Like '5 motor cluster'")];
}

-(NSString *)motorManufacturer{
    //the reason I am returning the manufacturer of the first motor is so that we can see a
    //manufacturer logo on screen (they are looked up based on this name)
    if ([self.internalMotors count]){
        return [(RocketMotor *)(self.internalMotors[0]) manufacturer];
    }
    return nil;
}

-(float)length{
    float maxLength = 0.0;
    for (RocketMotor *motor in self.internalMotors){
        if (motor.length > maxLength)
            maxLength = motor.length;
    }
    return maxLength;
}

-(float)totalImpulse{
    float impulse = 0.0;
    for (RocketMotor *motor in self.internalMotors){
        impulse += motor.totalImpulse;
    }
    return impulse;
}

-(float)massAtTime:(float)time{
    float motorMass = 0.0;
    for (RocketMotor *motor in self.internalMotors){
        motorMass += [motor massAtTime:time];
    }
    return self.mass + motorMass;
}

-(float)burnoutMass{
    // cache the result
    if (burrnoutMass) return burrnoutMass;
    return (burrnoutMass = [self massAtTime:self.burnoutTime]);
}

-(float)thrustAtTime:(float)time{
    float thrust = 0.0;
    for (NSArray *group in self.internalMotorsByGroup) {
        if ([group count]) {
            RocketMotor *motor = group[0];
            thrust += [group count] * [motor thrustAtTime:time];
        }
    }
    return thrust;
}

-(float)burnoutTime{        // this is the final burnout time of all loaded motors
    // cache the result
    if (burrnoutTime) return burrnoutTime;
    float time = 0.0;
    for (RocketMotor *motor in self.internalMotors) {
        float t = [[motor.times lastObject] floatValue] + motor.startDelay;
        if (t > time) time = t;
    }
    return burrnoutTime = time;
}

//-(NSArray *)burnoutTimes{
//#undef TIME_SLICE
//#define TIME_SLICE 0.05
//    if (!_burnoutTimes){
//        NSMutableArray *bTimes = [[NSMutableArray alloc] init];
//        // run through the entire burn and include every time the thrust goes to zero
//        float t = 0.0;
//        BOOL coasting = NO;
//        while (t < self.burnoutTime) {
//            t += TIME_SLICE;
//            if ([self thrustAtTime:t] == 0.0){
//                if (!coasting) [bTimes addObject:@(t)];
//                coasting = YES;
//            }else{
//                coasting = NO;
//            }
//        }
//        [bTimes addObject:@([self burnoutTime])];
//        
//        _burnoutTimes = [bTimes copy];
//    }
//    return _burnoutTimes;
//}

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
    burrnoutMass = 0.0;
    burrnoutTime = 0.0;
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
    [self replaceMotorLoadOutWithLoadOut:rocketProperties[ROCKET_LAST_LOADOUT_KEY]];
    self.motorConfig = rocketProperties[ROCKET_MOTOR_CONFIG_KEY];
    if (![self.motorConfig isKindOfClass:[NSArray class]]) {
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
    //    free(self.thrusts);
    self.internalMotorsByGroup = nil;
    self.internalMotors = nil;
    //    self.burnoutTimes = nil;
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
    if ([self motorLoadoutPlist]) rocketProperties[ROCKET_LAST_LOADOUT_KEY] = [self motorLoadoutPlist];
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
