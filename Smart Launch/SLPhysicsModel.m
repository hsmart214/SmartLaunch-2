//
//  SLPhysicsModel.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLPhysicsModel.h"
#import "SLDefinitions.h"

@interface SLPhysicsModel()

/* This is the opposing acceleration from gravity, the component of g along the axis of the launch guide */
@property (nonatomic) double altitude;      // y component of the rocket's position
@property (nonatomic) double travel;        // x component of the rocket's position
@property (nonatomic) double velocity;      // magnitude of the rocket's velocity vector
@property (nonatomic) double timeIndex;
@property (nonatomic, strong) NSMutableArray *flightProfile;
@property (nonatomic, strong) NSArray *stdAtmosphere;
@property (nonatomic) double angle;         // current 2D angle of flight
@property (nonatomic, strong) NSArray *thrusts;
@property (nonatomic, strong) NSArray *times;
@property (nonatomic) float motorInitialMass;
@property (nonatomic) float propellantMass;

@end

@implementation SLPhysicsModel

@synthesize launchGuideAngle = _launchGuideAngle;               //angle in RADIANS
@synthesize launchGuideLength = _launchGuideLength;             //length in METERS
@synthesize LaunchGuideDirection = _LaunchGuideDirection;       //crossWind, intoWind, withWind
@synthesize windVelocity = _windVelocity;                       //velocity in METERS/SECOND
@synthesize motor = _motor;
@synthesize rocket = _rocket;
@synthesize launchAltitude = _launchAltitude;                   //ground elevation in METERS
@synthesize flightProfile = _flightProfile;
@synthesize altitude = _altitude;                               //altitude AGL in METERS
@synthesize velocity = _velocity;                               //METERS/SECOND
@synthesize timeIndex = _timeIndex;                             //SECONDS since ignition (not first motion)

- (NSUInteger)version{
    return 2;
}

/* Going to break data encapsulation here for the sake of performance in the integration loops */

- (void)setMotor:(RocketMotor *)motor{
    if (_motor != motor){
        _motor = motor;
        self.thrusts = self.motor.thrusts;
        self.times = self.motor.times;
        self.motorInitialMass = [self.motor.loadedMass floatValue];
        self.propellantMass = [self.motor.propellantMass floatValue];
    }
}

-(CGFloat)thrustAtTime:(CGFloat)time{
    if ((time == 0.0) || (time >= [[_times lastObject] floatValue])) return 0.0;
    NSInteger i = 0;
    while ([[_times objectAtIndex:i] floatValue] < time) {
        i++;
    }   // i is now the index of the first thrust point AFTER time (can be zero)
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
    }
    return _stdAtmosphere;
}

- (void)resetFlight{
    self.flightProfile = nil;
}

// each element of this mutable array will be a point of the profile
// which will itself be an NSArray* (not mutable) consisting of four NSNumber*s - [time, altitude, velocity, accel]
- (NSMutableArray *)flightProfile{
    if (!_flightProfile){
        _flightProfile = [NSMutableArray array];
        [self integrateToEndOfLaunchGuide];
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

- (double)dragAtVelocity:(double)v
             andAltitude:(double)altAGL{
    if (v==0) return 0.0;
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

- (void)setLaunchGuideAngle:(float)angle{
    // Make sure the maximum deviation from vertical is not exceeded
    if (angle>MAX_LAUNCH_GUIDE_ANGLE) angle=MAX_LAUNCH_GUIDE_ANGLE;
    if (-angle>MAX_LAUNCH_GUIDE_ANGLE) angle=-MAX_LAUNCH_GUIDE_ANGLE;
    _launchGuideAngle = angle;    
}


- (double)velocityAtEndOfLaunchGuide{
    if (!self.liftMass) return 0;       // This will protect againt divide-by-zero errors
    double altitudeAtEndOfLaunchGuide = self.launchGuideLength * cos(self.launchGuideAngle);
    return [self velocityAtAltitude:altitudeAtEndOfLaunchGuide];
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

- (void)integrateToEndOfLaunchGuide{
    /*  During travel along the launch guide motion is constrained to a straight line, making the calculations easier for a time */
    self.altitude = 0;
    self.travel = 0;
    self.velocity = 0;
    self.timeIndex = 0;
    float mRocket = [self.rocket.mass floatValue];
    float burnoutTime = [[self.times lastObject] floatValue];
    double totalDistanceTravelled = 0;
    double distanceTravelled = 0;
    double g = GRAV_ACCEL * cos(_launchGuideAngle);
    
    while (totalDistanceTravelled < _launchGuideLength) {
        _timeIndex += 1.0/DIVS_DURING_BURN;
        double mass = [self.motor massAtTime:_timeIndex] + mRocket;
        double a = [self.motor thrustAtTime:_timeIndex]/mass - g - [self dragAtVelocity:_velocity andAltitude:_altitude]/mass;
        if (a > 0) {        //remember DIVS is in units of 1/sec
            distanceTravelled = (_velocity / DIVS_DURING_BURN) + (0.5 * a /(DIVS_DURING_BURN * DIVS_DURING_BURN));
            _altitude += distanceTravelled * cos(_launchGuideAngle);
            _travel += distanceTravelled * sin(_launchGuideAngle);
            _velocity += a / DIVS_DURING_BURN;
        }else{
            a = 0;
        }
        NSNumber *time = @(_timeIndex);
        NSNumber *vel = @(_velocity);
        NSNumber *alt = @(_altitude);
        NSNumber *trav = @(_travel);
        NSNumber *accel = @(a);
        [self.flightProfile addObject:@[time, alt, trav, vel, accel]];
        totalDistanceTravelled += distanceTravelled;
        if (_timeIndex >= burnoutTime && _velocity <= 0.0) break;           // Just in case you don't get off the pad
    }
}

- (void)integrateToBurnout{
    if (_timeIndex >= [[_times lastObject]floatValue] && _velocity <= 0.0) return;      // Just in case you didn't make it off the pad
    double t_squared = 1/ (DIVS_DURING_BURN * DIVS_DURING_BURN);
    self.angle = self.launchGuideAngle;
    float mRocket = [self.rocket.mass floatValue];
    float burnoutTime = [[self.motor.times lastObject] floatValue];
    
    while (_timeIndex <= burnoutTime) {
        _timeIndex += 1.0/DIVS_DURING_BURN;
        double g = GRAV_ACCEL * cos(_angle);
        double mass = [self.motor massAtTime:_timeIndex] + mRocket;
        double acc = [self.motor thrustAtTime:_timeIndex]/mass - [self dragAtVelocity:_velocity andAltitude:_altitude]/mass;
        
        double y_accel = acc * cos(_angle) - GRAV_ACCEL;
        double x_accel = acc * sin(_angle);
        double y_dist = _velocity * cos(_angle) / DIVS_DURING_BURN + (0.5 * y_accel * t_squared);
        double x_dist = _velocity * sin(_angle) / DIVS_DURING_BURN + (0.5 * x_accel * t_squared);
        _altitude += y_dist;
        _travel += x_dist;
        _velocity += (acc - g) / DIVS_DURING_BURN;

        _angle = atan(x_dist/y_dist);
        
        NSNumber *time = @(_timeIndex);
        NSNumber *vel = @(_velocity);
        NSNumber *alt = @(_altitude);
        NSNumber *trav = @(_travel);
        NSNumber *accel = @(acc);
        [self.flightProfile addObject:@[time, alt, trav, vel, accel]];
    }
    
}

- (void)integrateBurnoutToApogee{
    if (_timeIndex >= [[_times lastObject]floatValue] && _velocity <= 0.0) return;      // Just in case you are already stopped

    double t_squared = 1/ (DIVS_AFTER_BURNOUT * DIVS_AFTER_BURNOUT);
    double mass = [self.rocket.mass floatValue] + _motorInitialMass - _propellantMass;
    double deltaAlt = 1;
    while (deltaAlt > 0) {
        double g = GRAV_ACCEL * cos(_angle);
        _timeIndex += 1.0/DIVS_AFTER_BURNOUT;
        double acc = - [self dragAtVelocity:_velocity andAltitude:_altitude]/mass;
        double y_accel = acc * cos(_angle) - GRAV_ACCEL;
        double x_accel = acc * sin(_angle);
        double y_dist = _velocity * cos(_angle) / DIVS_AFTER_BURNOUT + (0.5 * y_accel * t_squared);
        double x_dist = _velocity * sin(_angle) / DIVS_AFTER_BURNOUT + (0.5 * x_accel * t_squared);
        _altitude += y_dist;
        deltaAlt = y_dist;
        _travel += x_dist;
        _velocity += (acc - g) / DIVS_AFTER_BURNOUT;
        
        _angle = atan(x_dist/y_dist);
        
        NSNumber *time = @(_timeIndex);
        NSNumber *vel = @(_velocity);
        NSNumber *alt = @(_altitude);
        NSNumber *trav = @(_travel);
        NSNumber *accel = @(acc);
        [self.flightProfile addObject:@[time, alt, trav, vel, accel]];
    }
}

- (double)velocityAtAltitude:(double)alt{
    if (alt <= 0) return 0;
    NSInteger counter = 0;
    for (NSInteger i = 0; i < [self.flightProfile count]; i++){
        NSArray *flightDataPoint = [_flightProfile objectAtIndex:i];
        double altAtIndex = [[flightDataPoint objectAtIndex:ALT_INDEX] doubleValue];
        if (altAtIndex > alt){
            counter = i;
            break;
        }
    }
    if ((!counter) || (counter == [_flightProfile count] - 1)) return 0;
    NSArray * p0 = [_flightProfile objectAtIndex:counter-1];
    NSArray * p1 = [_flightProfile objectAtIndex:counter];
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
    return [[[self.flightProfile lastObject] objectAtIndex:TIME_INDEX] doubleValue] - [[self.motor.times lastObject]floatValue];
}

//This one is for plotting the flight profile - gives back an array of data with the flight data with an increment (pixel width)

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
            if (++profileIndex >= [_flightProfile count]){
                [data addObject:[_flightProfile lastObject]];
                return [NSArray arrayWithArray:data];           // increment and test, return out if we overflow the flightProfile
            }
        }
        // now the profileIndex points to the first time point after the requested time.  Close enough to graph well
        [data addObject:[_flightProfile objectAtIndex:profileIndex]];
    }
    return [NSArray arrayWithArray:data];
}

// This next method is for the rapid updates necessary for the drawRect routine in the animated view

-(float)quickFFVelocityAtLaunchAngle:(float)angle andGuideLength:(float)length{
    float g = GRAV_ACCEL * cosf(angle);
    float dist = 0.0;   // This quick calculation ignores the difference between distance travelled and altitude
    float timedex = 0.0;
    float v = 0.0;
    float mRocket = [self.rocket.mass floatValue];
    //This will loop until the rocket JUST leaves the launch guide - close enough for display purposes
    while (dist < length) {
        timedex += 1.0/DIVS_DURING_BURN;
        float mass = [self.motor massAtTime:timedex] + mRocket;
        float a = [self.motor thrustAtTime:timedex]/mass - g - [self dragAtVelocity:v andAltitude:dist]/mass;
        if (a > 0) {        //remember DIVS is in units of 1/sec
            dist += (v / DIVS_DURING_BURN) + (0.5 * a /(DIVS_DURING_BURN * DIVS_DURING_BURN));
            v += a / DIVS_DURING_BURN;
        }
    }
    
    return v;
}

-(void)dealloc{
    self.flightProfile = nil;
    self.stdAtmosphere = nil;
    self.motor = nil;
    self.rocket = nil;
    self.times = nil;
    self.thrusts = nil;
}

@end
