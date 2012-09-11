//
//  RocketMotor.m
//  SafeLaunchMotorPicker
//
//  Created by J. Howard Smart on 6/16/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import "RocketMotor.h"

@interface RocketMotor()

@property (nonatomic, strong) NSNumber *mass;
@property (nonatomic, strong) NSNumber *calcTotalImpulse;
@property (nonatomic, strong) NSNumber *calcPeakThrust;


@end

@implementation RocketMotor

@synthesize mass = _mass;
@synthesize propellantMass = _propellantMass;
@synthesize times = _times;
@synthesize thrusts = _thrusts;
@synthesize name = _name;
@synthesize impulseClass = _impulseClass;
@synthesize diameter = _diameter;
@synthesize length = _length;
@synthesize manufacturer = _manufacturer;
@synthesize delays = _delays;
@synthesize calcPeakThrust = _calcPeakThrust;
@synthesize calcTotalImpulse = _calcTotalImpulse;

-(NSArray *)delays{
    return _delays;
}

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
    if ((time == 0.0) || (time >= [[self.times lastObject] floatValue])) return 0.0;
    NSInteger i = 0;
    while ([[self.times objectAtIndex:i] floatValue] < time) {
        i++;
    }
    double fiminus1 = 0.0;
    double timinus1 = 0.0;
    if (i>0) {
        fiminus1 = [[self.thrusts objectAtIndex:i-1] doubleValue];
        timinus1 = [[self.times objectAtIndex:i-1] doubleValue];
    }
    double dti = [[self.times objectAtIndex:i] doubleValue];
    double dfi = [[self.thrusts objectAtIndex:i] doubleValue];
    
    double ftime = fiminus1 + ((time - timinus1)/(dti - timinus1)) * (dfi - fiminus1);
    return ftime;
}

-(CGFloat)massAtTime:(CGFloat)time{
    double percentOfBurn = time / [[self.times lastObject] floatValue];
    if (percentOfBurn > 1.0) percentOfBurn = 1.0;
    return [self.mass floatValue] - percentOfBurn * [self.propellantMass floatValue];
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

+ (NSArray *)impulseClasses{
    return [NSArray arrayWithObjects:@"1/8 A", @"1/4 A", @"1/2 A", @"A", @"B", @"C", @"D",
            @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", nil];
}

+ (NSArray *)motorDiameters{
    return [NSArray arrayWithObjects:@"6mm", @"13mm", @"18mm", @"24mm", @"29mm",
            @"38mm", @"54mm", @"75mm", @"98mm", @"150mm", nil];
}

+ (RocketMotor *)defaultMotor{  // Estes D12
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
}

@end
