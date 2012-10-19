//
//  SLPhysicsModel.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import "SLPhysicsModel.h"
#import "SLDefinitions.h"

@interface SLPhysicsModel()

/* This is the opposing acceleration from gravity, the component of g along the axis of the launch guide */
@property (nonatomic) float gravityAccel;
/* This is the mass of the rocket plus the initial motor mass */
@property (nonatomic, readonly) float liftMass;
@property (nonatomic) double altitude;
@property (nonatomic) double velocity;
@property (nonatomic) double timeIndex;
@property (nonatomic) double burnoutTime;
@property (nonatomic, strong) NSMutableArray *flightProfile;
@property (nonatomic, strong) NSArray *stdAtmosphere;


@end

@implementation SLPhysicsModel

@synthesize stdAtmosphere = _stdAtmosphere;                     //
@synthesize gravityAccel = _gravityAccel;                       //acceleration due to gravity along the launch guide axis (positive, metric)
@synthesize prevSegmentEndVelocity = _prevSegmentEndVelocity;   //velocity in METERS/SECOND
@synthesize currSegmentEndVelocity = _currSegmentEndVelocity;   //velocity in METERS/SECOND
@synthesize launchGuideAngle = _launchGuideAngle;               //angle in RADIANS
@synthesize launchGuideLength = _launchGuideLength;             //length in METERS
@synthesize LaunchGuideDirection = _LaunchGuideDirection;       //crossWind, intoWind, withWind
@synthesize windVelocity = _windVelocity;                       //velocity in METERS/SECOND
@synthesize liftMass;                                           //mass in KILOGRAMS
@synthesize motor = _motor;
@synthesize rocket = _rocket;
@synthesize temperature = _temperature;                         //CELSIUS
@synthesize launchAltitude = _launchAltitude;                   //ground elevation in METERS
@synthesize flightProfile = _flightProfile;
@synthesize altitude = _altitude;                               //altitude AGL in METERS
@synthesize velocity = _velocity;                               //METERS/SECOND
@synthesize timeIndex = _timeIndex;                             //SECONDS since ignition (not first motion)
@synthesize burnoutTime = _burnoutTime;                         //SECONDS from ignition to burnout


- (NSArray *)stdAtmosphere{
    if (!_stdAtmosphere){
        NSMutableArray *build = [NSMutableArray array];
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSURL *atmosphereURL = [mainBundle URLForResource:@"atmosphere" withExtension:@"txt"];
        NSError *err;
        NSString *atmosphere = [NSString stringWithContentsOfURL:atmosphereURL encoding:NSUTF8StringEncoding error:&err];
        if (err){
            NSLog(@"%@, %@", @"Error reading atmosphere.txt",[err debugDescription]);
        }
        NSMutableArray *textLines = [NSMutableArray arrayWithArray:[atmosphere componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]]];
        while ([textLines count]) {
            if ([(NSString *)[textLines objectAtIndex:0] characterAtIndex:0] != ';'){
                NSArray *inputLine = [[textLines objectAtIndex:0] componentsSeparatedByCharactersInSet:
                                      [NSCharacterSet characterSetWithCharactersInString:@"\t"]];
                NSDictionary *stratification = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithFloat:[[inputLine objectAtIndex:0] floatValue]], ALT_MSL_KEY,
                                                [NSNumber numberWithFloat:[[inputLine objectAtIndex:1] floatValue]], PRESSURE_KEY,
                                                [NSNumber numberWithFloat:[[inputLine objectAtIndex:2] floatValue]], RHO_RATIO_KEY,
                                                [NSNumber numberWithFloat:[[inputLine objectAtIndex:1] floatValue]], MACH_ONE_KEY
                                                , nil];
                [build addObject:stratification];
            }
            [textLines removeObjectAtIndex:0];
        }
        _stdAtmosphere = build;
//        NSLog(@"%@ %d %@",@"Read in", [build count], @"atmosphere data points.");
    }
    return _stdAtmosphere;
}

- (void)resetFlight{
    self.flightProfile = nil;
    self.burnoutTime = 0.0;
}

// each element of this mutable array will be a point of the profile
// which will itself be an NSArray* (not mutable) consisting of four NSNumber*s - [time, altitude, velocity, accel]
- (NSMutableArray *)flightProfile{
    if (!_flightProfile){
        _flightProfile = [NSMutableArray array];
        [self integrateToBurnout];
        [self integrateBurnoutToApogee];
    }
    return _flightProfile;
}

- (NSDictionary *)atmosphereDataAtAltitudeAGL:(float)altAGL{
    NSInteger below = 0;
    NSInteger above = 1;
    NSInteger max = [self.stdAtmosphere count] - 1;
    float altMSL = altAGL + self.launchAltitude;
    if (altMSL >= [[[self.stdAtmosphere lastObject] objectForKey:ALT_MSL_KEY] floatValue]){
        return [self.stdAtmosphere lastObject];
    }
    while (above <= max){
        if (altMSL <= [[[self.stdAtmosphere objectAtIndex:above] objectForKey:ALT_MSL_KEY] floatValue]) break;
        above += 1;
    }
    below = above - 1;
    NSDictionary *aboveAtm = [self.stdAtmosphere objectAtIndex:above];
    NSDictionary *belowAtm = [self.stdAtmosphere objectAtIndex:below];
    float fraction = (altMSL - [[belowAtm objectForKey:ALT_MSL_KEY] floatValue]) / 
                        ([[aboveAtm objectForKey:ALT_MSL_KEY] floatValue] - [[belowAtm objectForKey:ALT_MSL_KEY] floatValue]);
    float temperature = fraction *([[aboveAtm objectForKey:TEMPERATURE_KEY] floatValue] - [[belowAtm objectForKey:TEMPERATURE_KEY] floatValue])
        + [[belowAtm objectForKey:TEMPERATURE_KEY] floatValue];
    float pressure = fraction *([[aboveAtm objectForKey:PRESSURE_KEY] floatValue] - [[belowAtm objectForKey:PRESSURE_KEY] floatValue])
        + [[belowAtm objectForKey:PRESSURE_KEY] floatValue];
    float rho_ratio = fraction *([[aboveAtm objectForKey:RHO_RATIO_KEY] floatValue] - [[belowAtm objectForKey:RHO_RATIO_KEY] floatValue])
        + [[belowAtm objectForKey:RHO_RATIO_KEY] floatValue];
    float mach_one = fraction *([[aboveAtm objectForKey:MACH_ONE_KEY] floatValue] - [[belowAtm objectForKey:MACH_ONE_KEY] floatValue])
        + [[belowAtm objectForKey:MACH_ONE_KEY] floatValue];
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithFloat:altMSL], ALT_MSL_KEY,
            [NSNumber numberWithFloat:temperature], TEMPERATURE_KEY,
            [NSNumber numberWithFloat:pressure], PRESSURE_KEY,
            [NSNumber numberWithFloat:rho_ratio], RHO_RATIO_KEY,
            [NSNumber numberWithFloat:mach_one], MACH_ONE_KEY, nil];
}

- (float)launchAltitude{
    if (!_launchAltitude){
        _launchAltitude = 0;                // get the altitude from prefs (prefs may use GPS if allowed)
    }
    return _launchAltitude;
}

- (float)temperature{
    if (!_temperature){
        _temperature = STANDARD_TEMP;        // change this to grab the temp from the user prefs
    }
    return _temperature;
}

//- (double)dragAtVelocity:(double)v 
//            andAltitude:(double)altAGL{
//    double currAlt = altAGL + self.launchAltitude;
//    // the temp at sea level would be technically higher based on the temperature lapse rate. (Theoretical only)
//    //double calcSeaLevelTemp = self.temperature + self.launchAltitude * T_LAPSE_RATE;
//    // this theoretical addition to the launch temp is backed out again in the next two calculations by using currAlt
//    //double currTemperature = calcSeaLevelTemp - currAlt * T_LAPSE_RATE;
//    double currTemperature = STANDARD_TEMP - currAlt * T_LAPSE_RATE;
//    //double pressure = STANDARD_PRESSURE * powf((1.0 - T_LAPSE_RATE * currAlt / calcSeaLevelTemp), PRESSURE_EXPONENT);
//    double pressure = STANDARD_PRESSURE * pow(((currTemperature + ABSOLUTE_ZERO_CELSIUS)/(STANDARD_TEMP)), PRESSURE_EXPONENT);
////    double density = pressure * MOLAR_MASS / (GAS_CONSTANT * (calcSeaLevelTemp - T_LAPSE_RATE * currAlt));
//    double density = pressure / (0.2869 * (currTemperature + ABSOLUTE_ZERO_CELSIUS));
//    double radius = [self.rocket.diameter floatValue]/2.0;
//    double area = _PI_*radius*radius;
//    // drag = 1/2 rho v^2 Cd A
//    return 0.5*density*v*v*[self.rocket.cd floatValue]*area;
//}

- (double)dragAtVelocity:(double)v
             andAltitude:(double)altAGL{
    NSDictionary *atmosphereData = [self atmosphereDataAtAltitudeAGL:altAGL];
    double radius = [self.rocket.diameter doubleValue]/2;
    double area = _PI_ * radius * radius;
    double rho = STANDARD_RHO * [[atmosphereData objectForKey:RHO_RATIO_KEY] floatValue];
    double cd = [self.rocket.cd floatValue];
    double ccd; // "corrected cd" adjusted for transonic region
    double mach = v / [[atmosphereData objectForKey:MACH_ONE_KEY] floatValue];
    // this uses the same mach correction the wRASP uses
    if (mach < 0.9) {
        ccd = cd;
    } else if (mach < 1.0) {
        ccd = cd * 2.0 * (mach - 0.8) / (1.0 - 0.8);
    } else if (mach < 1.2) {
        ccd = cd * (2.0 - ((mach - 1.0) / (1.2 - 1.0)));
    } else {
        ccd = cd;
    }
    // drag = 1/2 rho v^2 Cd A
    return 0.5*rho*v*v*ccd*area;
}

- (float)liftMass{
    return [self.rocket.mass floatValue] + [self.motor.loadedMass floatValue];
}

- (float)massAtTime:(float)time{
    return [self.rocket.mass floatValue] + [self.motor massAtTime:time];
}

- (void)setLaunchGuideAngle:(float)launchGuideAngle{
    
    // Make sure the maximum deviation from vertical is not exceeded
    if (launchGuideAngle>MAX_LAUNCH_GUIDE_ANGLE) launchGuideAngle=MAX_LAUNCH_GUIDE_ANGLE;
    if (-launchGuideAngle>MAX_LAUNCH_GUIDE_ANGLE) launchGuideAngle=-MAX_LAUNCH_GUIDE_ANGLE;
    _launchGuideAngle = launchGuideAngle;
    
    // Account for the slight diminution of gravity's effect from the tilting of the launch guide
    self.gravityAccel = GRAV_ACCEL*cos(launchGuideAngle);
}




- (double)velocityAtEndOfLaunchGuide{
    if (!self.liftMass) return 0;       // This will protect againt divide-by-zero errors
    return [self velocityAtAltitude:self.launchGuideLength];
}


- (float)freeFlightAngleOfAttack{
    if (!self.liftMass) return 0;       // This will protect againt divide-by-zero errors
    
    // All model angles are in radians.  It is up to the view to display degrees if desired
    float alpha1, alpha2, opposite, adjacent;
    double velocity = [self velocityAtEndOfLaunchGuide];
    // There is probably a better way to do this vector addition but I am not coming up with it right now
    switch (self.LaunchGuideDirection) {
        case CrossWind:
            return asinf(self.windVelocity/velocity);
            break;
        case WithWind:
            alpha1 = self.launchGuideAngle;
            opposite = velocity*sin(alpha1)-self.windVelocity;
            adjacent = velocity*cos(alpha1);
            alpha2 = atanf(opposite/adjacent);
            return alpha1-alpha2;
            break;
        case IntoWind:
            alpha1 = self.launchGuideAngle;
            opposite = velocity*sin(alpha1)+self.windVelocity;
            adjacent = velocity*cos(alpha1);
            alpha2 = atanf(opposite/adjacent);
            return alpha2-alpha1;
            break;
        default:
            return 0;
    }
}

#pragma mark Full Integration of Flight Profile

- (void)integrateToBurnout{
    self.altitude = 0;
    self.velocity = 0;
    self.timeIndex = 0;
    for (int i = 0; i < [self.motor.times count]; i++){
        while (self.timeIndex < [[self.motor.times objectAtIndex:i] floatValue]) {
            self.timeIndex += 1.0/DIVS_DURING_BURN;
            double mass = [self.motor massAtTime:self.timeIndex] + [self.rocket.mass floatValue];
            double a = [self.motor thrustAtTime:self.timeIndex]/mass - self.gravityAccel - [self dragAtVelocity:self.velocity andAltitude:self.altitude]/mass;
            if (a > 0) {        //remember DIVS is in units of 1/sec
                self.altitude += (self.velocity / DIVS_DURING_BURN) + (0.5 * a /(DIVS_DURING_BURN * DIVS_DURING_BURN));
                self.velocity += a / DIVS_DURING_BURN;
            }else{
                a = 0;
            }
            NSNumber *time = [NSNumber numberWithDouble:self.timeIndex];
            NSNumber *vel = [NSNumber numberWithDouble:self.velocity];
            NSNumber *alt = [NSNumber numberWithDouble:self.altitude];
            NSNumber *accel = [NSNumber numberWithDouble:a];
            [self.flightProfile addObject:[NSArray arrayWithObjects:time, alt, vel, accel, nil]];
        }
    }    
}

- (void)integrateBurnoutToApogee{
    while (self.velocity > 0) {
        self.timeIndex += 1.0/DIVS_AFTER_BURNOUT;
        double mass = [self.motor massAtTime:self.timeIndex] + [self.rocket.mass floatValue];
        double a = - self.gravityAccel - [self dragAtVelocity:self.velocity andAltitude:self.altitude]/mass;
        
        self.altitude += ((self.velocity / DIVS_AFTER_BURNOUT) + (0.5 * a /(DIVS_AFTER_BURNOUT * DIVS_AFTER_BURNOUT)) * cos(self.launchGuideAngle));
        self.velocity += a / DIVS_AFTER_BURNOUT;
        
        NSNumber *time = [NSNumber numberWithDouble:self.timeIndex];
        NSNumber *vel = [NSNumber numberWithDouble:self.velocity];
        NSNumber *alt = [NSNumber numberWithDouble:self.altitude];
        NSNumber *accel = [NSNumber numberWithDouble:a];
        
        [self.flightProfile addObject:[NSArray arrayWithObjects:time, alt, vel, accel, nil]];
    }
}

- (double)velocityAtAltitude:(double)alt{
    if (alt <= 0) return 0;
    NSInteger counter = 0;
    for (NSInteger i = 0; i < [self.flightProfile count]; i++){
        NSArray *flightDataPoint = [self.flightProfile objectAtIndex:i];
        double altAtIndex = [[flightDataPoint objectAtIndex:ALT_INDEX] doubleValue];
        //        NSLog(@"altitude = %3.3f", altAtIndex);
        if (altAtIndex > alt){
            counter = i;
            break;
        }
    }
    if ((!counter) || (counter == [self.flightProfile count] - 1)) return 0;
    NSArray * p0 = [self.flightProfile objectAtIndex:counter-1];
    NSArray * p1 = [self.flightProfile objectAtIndex:counter];
    double v0 = [[p0 objectAtIndex:VEL_INDEX] doubleValue];
    double v1 = [[p1 objectAtIndex:VEL_INDEX] doubleValue];
    double d0 = [[p0 objectAtIndex:ALT_INDEX] doubleValue];
    double d1 = [[p1 objectAtIndex:ALT_INDEX] doubleValue];
    double slope = (v1 - v0)/(d1 - d0);
    return (v0 + slope * (alt - d0));
}

- (double)apogee{
    return [[[self.flightProfile lastObject] objectAtIndex:ALT_INDEX] doubleValue];
}

- (double)burnoutToApogee{
    return [[[self.flightProfile lastObject] objectAtIndex:TIME_INDEX] doubleValue] - self.burnoutTime;
}

- (NSArray *)flightDataWithTimeIncrement:(float)increment{
    // time, altitude, velocity, acceleration
    // here I am going to make the simplifying assumption that the increment will be substantially larger than 1/DIVS
    // since it will be 1/ the number of pixels in one second of displayed profile - on the order of 1/100
    // so for each point I will take the flightProfile info at the first point AFTER the incremented time
    NSMutableArray *data = [NSMutableArray array];
    [data addObject:[NSArray arrayWithObjects:[NSNumber numberWithDouble:0.0], [NSNumber numberWithDouble:0.0], 
                     [NSNumber numberWithDouble:0.0], [NSNumber numberWithDouble:0.0],nil]];
    NSInteger profileIndex = 0;
    NSInteger dataIndex = 1;
    while (profileIndex < [self.flightProfile count]) {
        double stopTime = dataIndex++ * increment;
        while ([[[self.flightProfile objectAtIndex:profileIndex] objectAtIndex:TIME_INDEX] doubleValue] < stopTime) {
            if (++profileIndex >= [self.flightProfile count]){
                [data addObject:[self.flightProfile lastObject]];
                return [NSArray arrayWithArray:data];           // increment and test, return out if we overflow the flightProfile
            }
        }
        // now the profileIndex points to the first time point after the requested time.  Close enough to graph well
        [data addObject:[self.flightProfile objectAtIndex:profileIndex]];
    }
    return [NSArray arrayWithArray:data];
}

-(void)dealloc{
    self.flightProfile = nil;
    self.stdAtmosphere = nil;
    self.motor = nil;
    self.rocket = nil;
}

@end
