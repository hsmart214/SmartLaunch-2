//
//  RocketMotor.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/16/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "RocketMotor.h"

@interface RocketMotor()

@property (nonatomic, strong) NSNumber *mass;
@property (nonatomic, strong) NSNumber *calcTotalImpulse;
@property (nonatomic, strong) NSNumber *calcPeakThrust;

@end

@implementation RocketMotor

-(NSNumber *)loadedMass{
    return self.mass;
}

-(NSNumber *)peakThrust{
    return self.calcPeakThrust;
}

-(NSNumber *)totalImpulse{
    return self.calcTotalImpulse;
}

-(void)calculateDerivedValues{
    // curve starts at (0,0) which is NOT included in the arrays
    // use trapezoidal approximation to the area-under-the-curve
    double impulse = 0.5 * [[self.thrusts objectAtIndex:0] floatValue] * [[self.times objectAtIndex:0] floatValue];
    self.calcPeakThrust = [self.thrusts objectAtIndex:0];
    for (NSInteger i = 1; i < [self.times count]; i++) {
        if ([[self.thrusts objectAtIndex:i] floatValue] > [self.calcPeakThrust floatValue]) self.calcPeakThrust = [self.thrusts objectAtIndex:i]; // defines the first local maximum of the thrust curve.  Unlikely to have a second maximum
        double deltaT = [[self.times objectAtIndex:i] floatValue] - [[self.times objectAtIndex:i-1] floatValue];
        double fiminus1 = [[self.thrusts objectAtIndex:i-1] floatValue];
        double deltaF = [[self.thrusts objectAtIndex:i] floatValue] - fiminus1;
        impulse += 0.5 * deltaF * deltaT + fiminus1 * deltaT;
    }
    self.calcTotalImpulse = [NSNumber numberWithDouble:impulse];
}

-(RocketMotor *)initWithMotorDict:(NSDictionary *)motorDict{
    self.mass =           [motorDict objectForKey:MOTOR_MASS_KEY];
    _propellantMass = [motorDict objectForKey:PROP_MASS_KEY];
    _times =          [motorDict objectForKey:TIME_KEY];
    _thrusts =        [motorDict objectForKey:THRUST_KEY];
    _name =           [motorDict objectForKey:NAME_KEY];
    _manufacturer =   [motorDict objectForKey:MAN_KEY];
    _impulseClass =   [motorDict objectForKey:IMPULSE_KEY];
    _diameter =       [motorDict objectForKey:MOTOR_DIAM_KEY];
    _length =         [motorDict objectForKey:MOTOR_LENGTH_KEY];
    NSString *delayList = [motorDict objectForKey:DELAYS_KEY];
    _delays = [delayList componentsSeparatedByString:@"-"];
    [self calculateDerivedValues];
    return self;
}


-(NSDictionary *)motorDict{
    NSString *delayString = [self.delays objectAtIndex:0];
    if ([self.delays count]>1){
        for (int i = 1; i < [self.delays count]; i++) {
            delayString = [NSString stringWithFormat:@"%@-%@", delayString, [self.delays objectAtIndex:i]];
        }
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:
            self.mass, MOTOR_MASS_KEY,
            self.propellantMass, PROP_MASS_KEY,
            self.times, TIME_KEY,
            self.thrusts, THRUST_KEY,
            self.name, NAME_KEY,
            self.manufacturer, MAN_KEY,
            self.impulseClass, IMPULSE_KEY, 
            self.diameter, MOTOR_DIAM_KEY,
            self.length, MOTOR_LENGTH_KEY,
            delayString, DELAYS_KEY,
            nil];
}

-(CGFloat)thrustAtTime:(CGFloat)time{
    if ((time == 0.0) || (time >= [[_times lastObject] floatValue])) return 0.0;
    NSInteger i = 0;
    while ([[_times objectAtIndex:i] floatValue] < time) {
        i++;
    }
    double fiminus1 = 0.0;
    double timinus1 = 0.0;
    if (i>0) {
        fiminus1 = [[_thrusts objectAtIndex:i-1] doubleValue];
        timinus1 = [[_times objectAtIndex:i-1] doubleValue];
    }
    double dti = [[_times objectAtIndex:i] doubleValue];
    double dfi = [[_thrusts objectAtIndex:i] doubleValue];
    
    double ftime = fiminus1 + ((time - timinus1)/(dti - timinus1)) * (dfi - fiminus1);
    return ftime;
}

-(CGFloat)massAtTime:(CGFloat)time{
    double percentOfBurn = time / [[_times lastObject] floatValue];
    if (percentOfBurn > 1.0) percentOfBurn = 1.0;
    return [_mass floatValue] - percentOfBurn * [_propellantMass floatValue];
}

#pragma mark - RocketMotor Class methods


+(RocketMotor *)motorWithMotorDict:(NSDictionary *)motorDict{
    RocketMotor *motor = [[RocketMotor alloc] initWithMotorDict:(NSDictionary *)motorDict];
    return motor;
}

+ (NSArray *)manufacturerNames{
    return [NSArray arrayWithObjects:
            @"AMW Pro-X",
            @"Aerotech RMS",
            @"Aerotech",
            @"Aerotech Hybrid",
            @"Animal Motor Works",
            @"Apogee",
            @"Cesaroni",
            @"Contrail Rockets",
            @"Ellis Mountain",
            @"Estes",
            @"Gorilla Rocket Motors",
            @"Hypertek",
            @"Kosdon by Aerotech",
            @"Kosdon",
            @"Loki Research",
            @"Public Missiles Ltd",
            @"Propulsion Polymers",
            @"Quest",
            @"RATTworks",
            @"RoadRunner",
            @"Sky Ripper",
            @"West Coast Hybrids", nil];
}

+ (NSArray *)hybridManufacturerNames{
    return [NSArray arrayWithObjects:
            @"Aerotech Hybrid",
            @"Contrail Rockets",
            @"Hypertek",
            @"Propulsion Polymers",
            @"RATTworks",
            @"Sky Ripper",
            @"West Coast Hybrids", nil];
}


+ (NSArray *)impulseClasses{
    return [NSArray arrayWithObjects:@"1/8A", @"1/4A", @"1/2A", @"A", @"B", @"C", @"D",
            @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", nil];
}

+ (NSArray *)motorDiameters{
    return [NSArray arrayWithObjects:@"6mm", @"13mm", @"18mm", @"24mm", @"29mm",
            @"38mm", @"54mm", @"75mm", @"98mm", @"150mm", nil];
}

/*+ (RocketMotor *)defaultEstesMotor{  // Estes D12
    NSArray *times = [NSArray arrayWithObjects:
                      [NSNumber numberWithFloat:0.049],
                      [NSNumber numberWithFloat:0.166],
                      [NSNumber numberWithFloat:0.184],
                      [NSNumber numberWithFloat:0.237],
                      [NSNumber numberWithFloat:0.282],
                      [NSNumber numberWithFloat:0.297],
                      [NSNumber numberWithFloat:0.311],
                      [NSNumber numberWithFloat:0.322],
                      [NSNumber numberWithFloat:0.348],
                      [NSNumber numberWithFloat:0.386],
                      [NSNumber numberWithFloat:0.442],
                      [NSNumber numberWithFloat:0.546],
                      [NSNumber numberWithFloat:0.718],
                      [NSNumber numberWithFloat:0.879],
                      [NSNumber numberWithFloat:1.066],
                      [NSNumber numberWithFloat:1.257],
                      [NSNumber numberWithFloat:1.436],
                      [NSNumber numberWithFloat:1.59],
                      [NSNumber numberWithFloat:1.612],
                      [NSNumber numberWithFloat:1.65], nil];
    NSArray *thrusts = [NSArray arrayWithObjects:
                      [NSNumber numberWithFloat:2.569],
                      [NSNumber numberWithFloat:9.369],
                      [NSNumber numberWithFloat:17.275],
                      [NSNumber numberWithFloat:24.258],
                      [NSNumber numberWithFloat:29.73],
                      [NSNumber numberWithFloat:27.01],
                      [NSNumber numberWithFloat:22.589],
                      [NSNumber numberWithFloat:17.99],
                      [NSNumber numberWithFloat:14.126],
                      [NSNumber numberWithFloat:12.099],
                      [NSNumber numberWithFloat:10.808],
                      [NSNumber numberWithFloat:9.876],
                      [NSNumber numberWithFloat:9.306],
                      [NSNumber numberWithFloat:9.105],
                      [NSNumber numberWithFloat:8.901],
                      [NSNumber numberWithFloat:8.698],
                      [NSNumber numberWithFloat:8.31],
                      [NSNumber numberWithFloat:8.294],
                      [NSNumber numberWithFloat:4.613],
                      [NSNumber numberWithFloat:0.0], nil];
    NSDictionary *estesD12 = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat:0.0426], MOTOR_MASS_KEY,
                              [NSNumber numberWithFloat:0.0211], PROP_MASS_KEY,
                              times, TIME_KEY,
                              thrusts, THRUST_KEY,
                              @"D12", NAME_KEY,
                              @"Estes", MAN_KEY,
                              @"D", IMPULSE_KEY,
                              [NSNumber numberWithInteger:24], MOTOR_DIAM_KEY,
                              [NSNumber numberWithFloat:0.07], MOTOR_LENGTH_KEY,
                              @"0-3-5-7", DELAYS_KEY,
                              nil];
    return [RocketMotor motorWithMotorDict:estesD12];
}*/

+ (RocketMotor *)defaultMotor{
    NSArray *times = @[@(0.011),
    @(0.018),
    @(0.032),
    @(0.079),
    @(0.122),
    @(0.136),
    @(0.169),
    @(0.201),
    @(0.223),
    @(0.233),
    @(0.255),
    @(0.276),
    @(0.352),
    @(0.402),
    @(0.420),
    @(0.459),
    @(0.488),
    @(0.556),
    @(0.671),
    @(0.707),
    @(0.729),
    @(0.779),
    @(0.793),
    @(0.836),
    @(0.904),
    @(0.926),
    @(0.990),
    @(1.026),
    @(1.123),
    @(1.231),
    @(1.342),
    @(1.400)];
    NSArray *thrusts = @[@(14.506),
    @(25.13),
    @(20.938),
    @(19.065),
    @(21.139),
    @(19.686),
    @(21.139),
    @(20.728),
    @(21.76),
    @(20.938),
    @(21.97),
    @(20.938),
    @(20.728),
    @(20.107),
    @(20.728),
    @(20.107),
    @(20.517),
    @(18.243),
    @(15.959),
    @(14.717),
    @(15.127),
    @(12.853),
    @(13.474),
    @(11.401),
    @(10.158),
    @(10.569),
    @(8.083),
    @(8.498),
    @(6.011),
    @(2.487),
    @(0.829),
    @(0)];
    //D10 18 70 3-5-7 0.0098 0.0259 Apogee

    NSDictionary *apogeeD10 = @{NAME_KEY: @"D10",
        MOTOR_DIAM_KEY: @(18.0),
        MOTOR_LENGTH_KEY: @(70.0),
        DELAYS_KEY: @"3-5-7",
        PROP_MASS_KEY: @(0.0098),
        MOTOR_MASS_KEY: @(0.0259),
        MAN_KEY: @"Apogee",
        IMPULSE_KEY: @"D",
        TIME_KEY: times,
        THRUST_KEY: thrusts};
    return [RocketMotor motorWithMotorDict:apogeeD10];
}

+(NSDictionary *)manufacturerDict{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"AMW Pro-X", @"AMW_ProX",
            @"Aerotech RMS", @"A-RMS",
            @"Aerotech", @"A",
            @"Aerotech Hybrid", @"ATH",
            @"Animal Motor Works", @"AMW",
            @"Apogee", @"Apogee",
            @"Cesaroni", @"CTI",
            @"Contrail Rockets", @"Contrail_Rockets",
            @"Ellis Mountain", @"Ellis",
            @"Estes", @"Estes",
            @"Gorilla Rocket Motors", @"Gorilla_Rocket_Motors",
            @"Hypertek", @"HT",
            @"Kosdon by Aerotech", @"KA",
            @"Kosdon", @"KOS-TRM",
            @"Loki Research", @"Loki",
            @"Public Missiles Ltd", @"PML",
            @"Propulsion Polymers", @"Propul",
            @"Quest", @"Q",
            @"RATTworks", @"RATT",
            @"RoadRunner", @"RR",
            @"Sky Ripper", @"SkyRip",
            @"West Coast Hybrids", @"WCoast", nil];
}

NSInteger sortingFunction(id md1, id md2, void *context){
    NSString *first = [(NSDictionary *)md1 objectForKey:NAME_KEY];
    NSString *second = [(NSDictionary *)md2 objectForKey:NAME_KEY];
    if ([first characterAtIndex:0] > [second characterAtIndex:0]) return NSOrderedDescending;
    if ([first characterAtIndex:0] < [second characterAtIndex:0]) return NSOrderedAscending;
    // at this point we know the impulse class is the SAME, so sort by the average thrust
    NSInteger thrust1 = [[first substringFromIndex:1] integerValue];
    NSInteger thrust2 = [[second substringFromIndex:1] integerValue];
    if (thrust1 > thrust2) return NSOrderedDescending;
    if (thrust1 < thrust2) return NSOrderedAscending;
    return NSOrderedSame;
}

+(NSArray *)everyMotor{
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *defaults = [NSUbiquitousKeyValueStore defaultStore];
    NSInteger currentMotorsVersion = [defaults longLongForKey:MOTOR_FILE_VERSION_KEY];
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSInteger bundleMotorVersion = [[NSString stringWithContentsOfURL:[mainBundle URLForResource:MOTOR_VERSION_FILENAME withExtension:@"txt"] encoding:NSUTF8StringEncoding error:nil]integerValue];
    NSURL *cacheURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *motorFileURL = [cacheURL URLByAppendingPathComponent:EVERY_MOTOR_CACHE_FILENAME];
    if ([[NSFileManager defaultManager]fileExistsAtPath:[motorFileURL path]]){
        return [NSArray arrayWithContentsOfURL:motorFileURL];
    }
    NSMutableArray *build = [NSMutableArray array];
    
    NSURL *motorsURL = [mainBundle URLForResource:@"motors" withExtension:@"txt"];
    if (currentMotorsVersion > bundleMotorVersion){
        NSURL *docURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        motorsURL = [docURL URLByAppendingPathComponent:MOTOR_DATA_FILENAME];
    }
    NSError *err;
    NSString *motors = [NSString stringWithContentsOfURL:motorsURL encoding:NSUTF8StringEncoding error:&err];
    if (err){
        NSLog(@"%@, %@", @"Error reading motors.txt",[err debugDescription]);
    }
    NSMutableArray *textLines = [NSMutableArray arrayWithArray:[motors componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]]];
    while ([textLines count] > 0) {
        NSMutableDictionary *motorData = [NSMutableDictionary dictionary];
        NSString *header;
        while (true){ // remove all of the comment lines
            if ([[textLines objectAtIndex:0] characterAtIndex:0]== ';'){
                [textLines removeObjectAtIndex:0];
                if ([textLines count] == 0){
                    header = nil;
                    break;
                }
            }else{    // and grab the header line
                header = [textLines objectAtIndex:0];
                [textLines removeObjectAtIndex:0];
                break;
            }
        }
        if (!header) break;
        NSArray *chunks = [header componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [motorData setValue:[chunks objectAtIndex:0] forKey:NAME_KEY];
        [motorData setValue:[chunks objectAtIndex:1] forKey:MOTOR_DIAM_KEY];
        [motorData setValue:[chunks objectAtIndex:2] forKey:MOTOR_LENGTH_KEY];
        [motorData setValue:[chunks objectAtIndex:3] forKey:DELAYS_KEY];
        [motorData setValue:[chunks objectAtIndex:4] forKey:PROP_MASS_KEY];
        [motorData setValue:[chunks objectAtIndex:5] forKey:MOTOR_MASS_KEY];
        [motorData setValue:[[RocketMotor manufacturerDict] objectForKey:[chunks objectAtIndex:6]] forKey:MAN_KEY];
        // figure out the impulse class from the motor name in the header line
        
        NSString *mname = [chunks objectAtIndex:0];
        if ([[mname substringToIndex:2] isEqualToString:@"MM"]) {
            [motorData setValue:@"1/8A" forKey:IMPULSE_KEY];
        }
        else if ([[mname substringToIndex:2] isEqualToString:@"1/"]) {
            [motorData setValue:[mname substringToIndex:4] forKey:IMPULSE_KEY];
        }
        else {
            [motorData setValue:[mname substringToIndex:1] forKey:IMPULSE_KEY];
        }
        // after the header the lines are all time / thrust pairs until the thrust is zero
        NSMutableArray *times = [NSMutableArray array];
        NSMutableArray *thrusts = [NSMutableArray array];
        while (true){
            chunks = [[textLines objectAtIndex:0] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            chunks = [NSArray arrayWithObjects:[chunks objectAtIndex:0], [chunks lastObject], nil];
            [times addObject:[NSNumber numberWithFloat:[[chunks objectAtIndex:0] floatValue]]];
            [thrusts addObject:[NSNumber numberWithFloat:[[chunks objectAtIndex:1] floatValue]]];
            [textLines removeObjectAtIndex:0];
            if ([[chunks objectAtIndex:1] floatValue] == 0.0) break;
        }
        [motorData setValue:times forKey:TIME_KEY];
        [motorData setValue:thrusts forKey:THRUST_KEY];
        
        [build addObject:motorData];
    }
    NSArray *allMotors = [[NSArray arrayWithArray:build] sortedArrayUsingFunction:sortingFunction context:NULL];
    [allMotors writeToURL:motorFileURL atomically:YES];
    //NSLog(@"Loaded %d motors.",[_allMotors count]);

    return allMotors;
}

-(void)dealloc{
    _mass = nil;
    _propellantMass = nil;
    _times = nil;
    _thrusts = nil;
    _name = nil;
    _manufacturer = nil;
    _impulseClass = nil;
    _diameter = nil;
    _length = nil;
    _delays = nil;
    _calcPeakThrust = nil;
    _calcTotalImpulse = nil;
}
@end
