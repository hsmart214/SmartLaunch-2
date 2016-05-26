//
//  RocketMotor.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/16/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "RocketMotor.h"

@interface RocketMotor()

@property (nonatomic) float mass;
@property (nonatomic) float calcTotalImpulse;
@property (nonatomic) float calcPeakThrust;

@end

@implementation RocketMotor

static NSMutableDictionary *sMotorsByName;

-(float)burnoutTime{
    return [[self.times lastObject] floatValue] + self.startDelay;
}

-(float)loadedMass{
    return self.mass;
}

-(float)peakThrust{
    return self.calcPeakThrust;
}

-(float)totalImpulse{
    return self.calcTotalImpulse;
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

-(NSString *)nextImpulseClass{
    for (int i = 0; i < [[RocketMotor impulseClasses] count]-1; i++) {
        if ([self.impulseClass isEqualToString:[RocketMotor impulseClasses][i]]){
            return [RocketMotor impulseClasses][i+1];
        }
    }
    return [[[RocketMotor impulseClasses] lastObject] stringByAppendingString:@"+"];;
}

-(void)calculateDerivedValues{
    // curve starts at (0,0) which is NOT included in the arrays
    // use trapezoidal approximation to the area-under-the-curve
    double impulse = 0.5 * [(self.thrusts)[0] floatValue] * [(self.times)[0] floatValue];
    self.calcPeakThrust = [self.thrusts[0] floatValue];
    for (NSInteger i = 1; i < [self.times count]; i++) {
        if ([(self.thrusts)[i] floatValue] > self.calcPeakThrust) self.calcPeakThrust = [self.thrusts[i] floatValue]; // defines the first local maximum of the thrust curve.  Unlikely to have a second maximum (haha)
        double deltaT = [(self.times)[i] floatValue] - [(self.times)[i-1] floatValue];
        double fiminus1 = [(self.thrusts)[i-1] floatValue];
        double deltaF = [(self.thrusts)[i] floatValue] - fiminus1;
        impulse += 0.5 * deltaF * deltaT + fiminus1 * deltaT;
    }
    self.calcTotalImpulse = impulse;
}

// Designated initializer
-(instancetype)initWithMotorDict:(NSDictionary *)motorDict{
    _mass =       [motorDict[MOTOR_MASS_KEY] floatValue];
    _propellantMass = [motorDict[PROP_MASS_KEY] floatValue];
    _times =          motorDict[TIME_KEY];
    _thrusts =        motorDict[THRUST_KEY];
    _name =           motorDict[NAME_KEY];
    _manufacturer =   motorDict[MAN_KEY];
    _impulseClass =   motorDict[IMPULSE_KEY];
    _diameter =       [motorDict[MOTOR_DIAM_KEY] integerValue];
    _length =         [motorDict[MOTOR_LENGTH_KEY] floatValue];
    NSString *delayList = motorDict[DELAYS_KEY];
    _delays = [delayList componentsSeparatedByString:@"-"];
    if ([self.thrusts count] != [self.times count]){
        NSLog(@"RocketMotor init with bad thrust curve data: %@",self.name);
        return nil;
    }
    _startDelay = [motorDict[CLUSTER_START_DELAY_KEY] floatValue];  // will be zero if the key does not exist (this is correct)
    [self calculateDerivedValues];
    // if this is the first motor created during this run of the program we need to fire off a thread
    // to populate the motors-by-name dictionary
    if (!sMotorsByName){
        dispatch_async(dispatch_queue_create("motor dict queue", DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            sMotorsByName = [NSMutableDictionary new];
            for (NSDictionary *motorDict in [RocketMotor everyMotor]){
                NSString *motorName = motorDict[NAME_KEY];
                sMotorsByName[motorName] = motorDict;
            }
        });
    }
    return self;
}


-(NSDictionary *)motorDict{
    NSString *delayString = (self.delays)[0];
    if ([self.delays count]>1){
        for (int i = 1; i < [self.delays count]; i++) {
            delayString = [NSString stringWithFormat:@"%@-%@", delayString, (self.delays)[i]];
        }
    }
    return @{MOTOR_MASS_KEY: @(self.mass),
            PROP_MASS_KEY: @(self.propellantMass),
            TIME_KEY: self.times,
            THRUST_KEY: self.thrusts,
            NAME_KEY: self.name,
            MAN_KEY: self.manufacturer,
            IMPULSE_KEY: self.impulseClass, 
            MOTOR_DIAM_KEY: @(self.diameter),
            MOTOR_LENGTH_KEY: @(self.length),
            DELAYS_KEY: delayString,
            CLUSTER_START_DELAY_KEY: @(self.startDelay)};
}

-(float)thrustAtTime:(float)time{
    time = time - self.startDelay;
    if ((time <= 0.0) || (time >= [[_times lastObject] floatValue])) return 0.0;
    NSInteger i = 0;
    while ([_times[i] floatValue] < time) {
        i++;
    }
    double fiminus1 = 0.0;
    double timinus1 = 0.0;
    if (i>0) {
        fiminus1 = [_thrusts[i-1] doubleValue];
        timinus1 = [_times[i-1] doubleValue];
    }
    double dti = [_times[i] doubleValue];
    double dfi = [_thrusts[i] doubleValue];
    
    double ftime = fiminus1 + ((time - timinus1)/(dti - timinus1)) * (dfi - fiminus1);
    return ftime;
}

-(float)massAtTime:(float)time{
    time = time - self.startDelay;
    double percentOfBurn = time / [[_times lastObject] floatValue];
    if (percentOfBurn > 1.0) percentOfBurn = 1.0;
    return self.mass - percentOfBurn * self.propellantMass;
}

#pragma mark - RocketMotor Class methods


+(RocketMotor *)motorWithMotorDict:(NSDictionary *)motorDict{
    if (!motorDict) return nil;
    RocketMotor *motor = [[RocketMotor alloc] initWithMotorDict:motorDict];
    return motor;
}

+ (NSArray *)manufacturerNames{
    return @[@"AMW Pro-X",
            @"Aerotech RMS",
            @"Aerotech SU",
            @"Aerotech DMS",
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
            @"West Coast Hybrids"];
}

+ (NSArray *)hybridManufacturerNames{
    return @[@"Aerotech Hybrid",
            @"Contrail Rockets",
            @"Hypertek",
            @"Propulsion Polymers",
            @"RATTworks",
            @"Sky Ripper",
            @"West Coast Hybrids"];
}


+ (NSArray *)impulseClasses{
    return @[@"1/8A", @"1/4A", @"1/2A", @"A", @"B", @"C", @"D",
             @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M",
             @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V",
             @"W", @"X", @"Y", @"Z", @"AA"];
}

+ (NSArray *)impulseLimits{
    NSArray *iClasses = [RocketMotor impulseClasses];
    NSMutableArray *limits = [NSMutableArray array];
    float limit = FIRST_IMPULSE_CLASS_LIMIT;
    for (int i = 0; i < [iClasses count]; i++){
        [limits addObject:@(limit)];
        limit *= 2.0;
    }
    return [limits copy];
}

+ (NSString *)impulseClassForTotalImpulse:(float)totalImpulse{
    NSArray *iClasses = [RocketMotor impulseClasses];
    NSArray *iLimits = [RocketMotor impulseLimits];
    for (int i = 0; i < [iLimits count]; i++){
        float lim = [iLimits[i] floatValue];
        if (lim > totalImpulse){
            return iClasses[i];
        }
    }
    return [[[RocketMotor impulseClasses] lastObject] stringByAppendingString:@"+"];
}

+ (NSArray *)motorDiameters{
    return @[@"6mm", @"13mm", @"18mm", @"24mm", @"29mm",
            @"38mm", @"54mm", @"75mm", @"98mm", @"150mm"];
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
        MOTOR_DIAM_KEY: @(18),
        MOTOR_LENGTH_KEY: @(70.0),
        DELAYS_KEY: @"3-5-7",
        PROP_MASS_KEY: @0.0098,
        MOTOR_MASS_KEY: @0.0259,
        MAN_KEY: @"Apogee",
        IMPULSE_KEY: @"D",
        TIME_KEY: times,
        THRUST_KEY: thrusts};
    return [RocketMotor motorWithMotorDict:apogeeD10];
}

+(NSDictionary *)manufacturerDict{
    return @{@"AMW_ProX": @"AMW Pro-X",
            @"A-RMS": @"Aerotech RMS",
            @"A": @"Aerotech SU",
            @"A-DMS": @"Aerotech DMS",
            @"ATH": @"Aerotech Hybrid",
            @"AMW": @"Animal Motor Works",
            @"Apogee": @"Apogee",
            @"CTI": @"Cesaroni",
            @"Contrail_Rockets": @"Contrail Rockets",
            @"Ellis": @"Ellis Mountain",
            @"Estes": @"Estes",
            @"Gorilla_Rocket_Motors": @"Gorilla Rocket Motors",
            @"HT": @"Hypertek",
            @"KA": @"Kosdon by Aerotech",
            @"KOS-TRM": @"Kosdon",
            @"Loki": @"Loki Research",
            @"PML": @"Public Missiles Ltd",
            @"Propul": @"Propulsion Polymers",
            @"Q": @"Quest",
            @"RATT": @"RATTworks",
            @"RR": @"RoadRunner",
            @"SkyRip": @"Sky Ripper",
            @"WCoast": @"West Coast Hybrids"};
}

NSInteger sortingFunction(id md1, id md2, void *context){
    NSString *first = ((NSDictionary *)md1)[NAME_KEY];
    NSString *second = ((NSDictionary *)md2)[NAME_KEY];
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
    /* This method first tries to get the motor list from a cached file if it exists in the file system
       If it does not exist, it reads the motors from the motors.txt file one by one and formats them into
       motor dictionary plists, and stores them in the array that is eventually returned.  This operation
       is not very performant, which is why the result is cached.  It only needs to be recreated if the motor
       file version changes, which would happen when the motor file is updated from the website.
     
       It is also worth noting that the code for reading in the motors is not very forgiving of the format
       of the motors.txt file.  Stray empty lines or trailing space will kill it.  I should probably work
       on the error tolerance of it, but since I create the motors.txt file, I am responsible for making
       sure the formatting is correct.  If it ain't broke...
     */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger currentMotorsVersion = [defaults integerForKey:MOTOR_FILE_VERSION_KEY];
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
            if ([textLines[0] characterAtIndex:0]== ';'){
                [textLines removeObjectAtIndex:0];
                if ([textLines count] == 0){
                    header = nil;
                    break;
                }
            }else{    // and grab the header line
                header = textLines[0];
                [textLines removeObjectAtIndex:0];
                break;
            }
        }
        if (!header) break;
        NSArray *chunks = [header componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [motorData setValue:chunks[0] forKey:NAME_KEY];
        [motorData setValue:chunks[1] forKey:MOTOR_DIAM_KEY];
        [motorData setValue:chunks[2] forKey:MOTOR_LENGTH_KEY];
        [motorData setValue:chunks[3] forKey:DELAYS_KEY];
        [motorData setValue:chunks[4] forKey:PROP_MASS_KEY];
        [motorData setValue:chunks[5] forKey:MOTOR_MASS_KEY];
        [motorData setValue:[RocketMotor manufacturerDict][chunks[6]] forKey:MAN_KEY];
        // figure out the impulse class from the motor name in the header line
        
        NSString *mname = chunks[0];
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
            chunks = [textLines[0] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            chunks = @[chunks[0], [chunks lastObject]];
            [times addObject:@([chunks[0] floatValue])];
            [thrusts addObject:@([chunks[1] floatValue])];
            [textLines removeObjectAtIndex:0];
            if ([chunks[1] floatValue] == 0.0) break;
        }
        [motorData setValue:times forKey:TIME_KEY];
        [motorData setValue:thrusts forKey:THRUST_KEY];
        
        [build addObject:motorData];
    }
    NSArray *allMotors = [[NSArray arrayWithArray:build] sortedArrayUsingFunction:sortingFunction context:NULL];
    [allMotors writeToURL:motorFileURL atomically:YES];

    return allMotors;
}

+(double)totalImpulseOfMotorWithName:(NSString *)motorName{
    NSDictionary *motorDict = sMotorsByName[motorName];
    if (motorDict){
        RocketMotor *motor = [RocketMotor motorWithMotorDict:motorDict];
        return [motor totalImpulse];
    }else{
        return 0.0;
    }
}

-(NSString *)description{
    return [NSString stringWithFormat:@"%@ %@",self.manufacturer, self.name];
}

-(BOOL)isEqual:(id)object{
    return ([object isKindOfClass:[self class]] &&
            [[(RocketMotor *)object name] isEqualToString:self.name]);
}

-(void)dealloc{
    _times = nil;
    _thrusts = nil;
    _name = nil;
    _manufacturer = nil;
    _impulseClass = nil;
    _delays = nil;
}
@end
