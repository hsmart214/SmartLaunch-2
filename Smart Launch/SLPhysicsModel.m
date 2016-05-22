//
//  SLPhysicsModel.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLPhysicsModel.h"
#import "SLFlightDataPoint.h"

typedef struct  {
    float altMSL;
    float rho_ratio;
    float mach_one;
} SLCurrentEnvironment;

@interface SLPhysicsModel() <SLPhysicsModelDatasource>
{
    float topAltitude;
    int currentStdAtmSegment;
    float currentStdAtmBaseAlt, currentStdAtmCeilingAlt;
    float currentBaseRhoRatio, currentCeilingRhoRatio;
    float currentBaseMach, currentCeilingMach;
}

/* This is the opposing acceleration from gravity, the component of g along the axis of the launch guide */
@property (nonatomic) double altitude;      // y component of the rocket's position
@property (nonatomic) double travel;        // x component of the rocket's position
@property (nonatomic) double velocity;      // magnitude of the rocket's velocity vector
@property (nonatomic) float machNumber;
@property (nonatomic) float brnoutVelocity;
@property (nonatomic) double timeIndex;
@property (nonatomic, strong) NSMutableArray *flightProfile;
@property (nonatomic, strong) NSArray *stdAtmosphere;
@property (nonatomic) double angle;         // current 2D angle of flight
@property (nonatomic, strong) SLFlightDataPoint *maxValues;

@end

@implementation SLPhysicsModel

+(double)totalImpulseFromFlightSettings:(NSDictionary *)settings{
    
    SLClusterMotor *cMotor = [[SLClusterMotor alloc] initWithMotorLoadout:settings[SELECTED_MOTOR_KEY]];
    
    return cMotor.totalImpulse;
}

+(instancetype)sharedModel
{
    static SLPhysicsModel *sModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sModel = [SLPhysicsModel new];
    });
    return sModel;
}

-(BOOL)hasValidData
{
    return ([_flightProfile count] > 0);
}

- (float)version{
    return SMART_LAUNCH_VERSION;
}

- (void)setRocket:(Rocket *)rocket{
    _rocket = rocket;
    [self resetFlight];
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
            if ([(NSString *)textLines[0] characterAtIndex:0] != ';'){
                NSArray *inputLine = [textLines[0] componentsSeparatedByCharactersInSet:
                                      [NSCharacterSet characterSetWithCharactersInString:@"\t"]];
                NSDictionary *stratification = @{ALT_MSL_KEY: @([inputLine[0] floatValue]),
                                                 PRESSURE_KEY: @([inputLine[1] floatValue]),
                                                 RHO_RATIO_KEY: @([inputLine[2] floatValue]),
                                                 MACH_ONE_KEY: @([inputLine[1] floatValue])};
                [build addObject:stratification];
            }

            [textLines removeObjectAtIndex:0];
        } 
        _stdAtmosphere = build;
    }
    return _stdAtmosphere;
}

- (void)resetFlight{
    _flightProfile = nil;
    _maxValues = nil;
}

// each element of this mutable array will be a point of the profile
// which will itself be an NSArray* (not mutable) consisting of seven NSNumber*s - [time, alt, trav, vel, accel, mach, drg]
- (NSMutableArray *)flightProfile{
    if (!_flightProfile){
        _flightProfile = [NSMutableArray array];
        topAltitude = [[self.stdAtmosphere lastObject][ALT_MSL_KEY] floatValue];
        currentStdAtmSegment = 0;
        currentStdAtmBaseAlt = 0.0;
        currentStdAtmCeilingAlt = [_stdAtmosphere[1][ALT_MSL_KEY] floatValue];
        currentBaseMach = [_stdAtmosphere[0][MACH_ONE_KEY] floatValue];
        currentCeilingMach = [_stdAtmosphere[1][MACH_ONE_KEY] floatValue];
        currentBaseRhoRatio = [_stdAtmosphere[0][RHO_RATIO_KEY] floatValue];
        currentCeilingRhoRatio = [_stdAtmosphere[1][RHO_RATIO_KEY] floatValue];
        [self integrateToEndOfLaunchGuide];
        [self integrateToBurnout];
        [self integrateBurnoutToApogee];
    }
    return _flightProfile;
}

- (SLCurrentEnvironment)convertAtmosphereDictionary:(NSDictionary *)atmosphereDict
{
    SLCurrentEnvironment env;
    env.altMSL = [atmosphereDict[ALT_MSL_KEY] floatValue];
    env.rho_ratio = [atmosphereDict[RHO_RATIO_KEY] floatValue];
    env.mach_one = [atmosphereDict[MACH_ONE_KEY] floatValue];

    return env;
}

- (SLCurrentEnvironment)atmosphereDataAtAltitudeAGL:(float)altAGL{
    float altMSL = altAGL + _launchAltitude;
    if (altMSL >= topAltitude){
        return [self convertAtmosphereDictionary:[_stdAtmosphere lastObject]];
    }
    if (altMSL > currentStdAtmCeilingAlt){
        if (++currentStdAtmSegment == [_stdAtmosphere count]) {
            return [self convertAtmosphereDictionary:[_stdAtmosphere lastObject]];
        }
        currentStdAtmBaseAlt = currentStdAtmCeilingAlt;
        currentStdAtmCeilingAlt = [_stdAtmosphere[currentStdAtmSegment+1][ALT_MSL_KEY] floatValue];
        currentBaseRhoRatio = currentCeilingRhoRatio;
        currentCeilingRhoRatio = [_stdAtmosphere[currentStdAtmSegment+1][RHO_RATIO_KEY] floatValue];
        currentBaseMach = currentCeilingMach;
        currentCeilingMach = [_stdAtmosphere[currentStdAtmSegment+1][MACH_ONE_KEY] floatValue];
    }
    float fraction = (altMSL - currentStdAtmBaseAlt) /
    (currentStdAtmCeilingAlt - currentStdAtmBaseAlt);
    float rho_ratio = fraction *(currentCeilingRhoRatio - currentBaseRhoRatio)
    + currentBaseRhoRatio;
    float mach_one = fraction *(currentCeilingMach - currentBaseMach)
    + currentBaseMach;
    SLCurrentEnvironment env;
    env.altMSL = altMSL;
    env.rho_ratio = rho_ratio;
    env.mach_one = mach_one;

    return env;
}

- (float)launchAltitude{
    if (!_launchAltitude){
        _launchAltitude = 0;                // get the altitude from prefs (prefs may use GPS if allowed)
    }
    return _launchAltitude;
}

- (double)dragAtVelocity:(double)v
                    time:(float)time
             andAltitude:(double)altAGL{
    if (v==0) return 0.0;
    SLCurrentEnvironment atmosphereData = [self atmosphereDataAtAltitudeAGL:altAGL]; //OPT 68% -> 14%
    double rho = STANDARD_RHO * atmosphereData.rho_ratio; //OPT 10% -> 0
    double cd = [_rocket cdAtTime:time]; //OPT 6% -> 42%
    double ccd; // "corrected cd" adjusted for transonic region
    double mach = v / atmosphereData.mach_one; //OPT 8% -> 0
    _machNumber = mach;
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
    float area = [_rocket areaAtTime:time]; //OPT 39%
    return 0.5*rho*v*v*ccd*area; //OPT 6% -> 42% ^
}

- (float)liftMass{
    return [self.rocket massAtTime:0.0];
}

- (void)setLaunchGuideAngle:(float)angle{
    // Make sure the maximum deviation from vertical is not exceeded
    if (angle>MAX_LAUNCH_GUIDE_ANGLE) angle=MAX_LAUNCH_GUIDE_ANGLE;
    if (-angle>MAX_LAUNCH_GUIDE_ANGLE) angle=-MAX_LAUNCH_GUIDE_ANGLE;
    _launchGuideAngle = angle;
}


- (float)velocityAtEndOfLaunchGuide{
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
    double totalDistanceTravelled = 0;
    double distanceTravelled = 0;
    double g = GRAV_ACCEL * cos(_launchGuideAngle);

    while (totalDistanceTravelled < _launchGuideLength) {
        _timeIndex += 1.0/DIVS_DURING_BURN;
        double mass = [self.rocket massAtTime:_timeIndex];
        double drag = [self dragAtVelocity:_velocity time: _timeIndex andAltitude:_altitude];
        double a = [self.rocket thrustAtTime:_timeIndex]/mass - g - drag/mass;
        if (a > 0) {        //remember DIVS is in units of 1/sec
            distanceTravelled = (_velocity / DIVS_DURING_BURN) + (0.5 * a /(DIVS_DURING_BURN * DIVS_DURING_BURN));
            _altitude += distanceTravelled * cos(_launchGuideAngle);
            _travel += distanceTravelled * sin(_launchGuideAngle);
            _velocity += a / DIVS_DURING_BURN;
        }else{
            a = 0;
        }
        SLFlightDataPoint *dataPoint = [SLFlightDataPoint new];
        dataPoint->time = _timeIndex;
        dataPoint->vel = _velocity;
        dataPoint->alt = _altitude;
        dataPoint->trav = _travel;
        dataPoint->accel = a;
        dataPoint->mach = _machNumber;
        dataPoint->drag = drag;

        [self.flightProfile addObject:dataPoint];

        totalDistanceTravelled += distanceTravelled;
        if (_timeIndex >= [self.rocket burnoutTime] && _velocity <= 0.0) break;           // Just in case you don't get off the pad
    }
}

- (void)integrateToBurnout{
    if (_timeIndex >= [self.rocket burnoutTime] && _velocity <= 0.0) return;      // Just in case you didn't make it off the pad
    double t_squared = 1/ (DIVS_DURING_BURN * DIVS_DURING_BURN);
    self.angle = self.launchGuideAngle;
    float burnoutTime = [self.rocket burnoutTime];

    while (_timeIndex <= burnoutTime) {
        _timeIndex += 1.0/DIVS_DURING_BURN;
        double g = GRAV_ACCEL * cos(_angle);
        double mass = [self.rocket massAtTime:_timeIndex];
        double drag = [self dragAtVelocity:_velocity time:_timeIndex andAltitude:_altitude];
        double acc = [self.rocket thrustAtTime:_timeIndex]/mass - drag/mass;

        double y_accel = acc * cos(_angle) - GRAV_ACCEL;
        double x_accel = acc * sin(_angle);
        double y_dist = _velocity * cos(_angle) / DIVS_DURING_BURN + (0.5 * y_accel * t_squared);
        double x_dist = _velocity * sin(_angle) / DIVS_DURING_BURN + (0.5 * x_accel * t_squared);
        _altitude += y_dist;
        _travel += x_dist;
        _velocity += (acc - g) / DIVS_DURING_BURN;

        _angle = atan(x_dist/y_dist);

        SLFlightDataPoint *dataPoint = [SLFlightDataPoint new];
        dataPoint->time = _timeIndex;
        dataPoint->vel = _velocity;
        dataPoint->alt = _altitude;
        dataPoint->trav = _travel;
        dataPoint->accel = acc;
        dataPoint->mach = _machNumber;
        dataPoint->drag = drag;

        [self.flightProfile addObject:dataPoint];
    }
    // It turns out this is not very useful.
    // If the motor thrust trails off at the end, which is common, then burnout velocity is much less than max velocity
    self.brnoutVelocity = _velocity;
}

- (void)integrateBurnoutToApogee{
    if (_timeIndex >= [self.rocket burnoutTime] && _velocity <= 0.0) return;      // Just in case you are already stopped
    float time = [self.rocket burnoutTime];
    double t_squared = 1/ (DIVS_AFTER_BURNOUT * DIVS_AFTER_BURNOUT);
    double mass = [self.rocket burnoutMass];
    double deltaAlt = 1;
    while (deltaAlt > 0) {
        double g = GRAV_ACCEL * cos(_angle);
        _timeIndex += 1.0/DIVS_AFTER_BURNOUT;
        double drag = [self dragAtVelocity:_velocity time:time andAltitude:_altitude]; //OPT -> 17%
        double acc = - drag/mass;
        double y_accel = acc * cos(_angle) - GRAV_ACCEL;
        double x_accel = acc * sin(_angle);
        double y_dist = _velocity * cos(_angle) / DIVS_AFTER_BURNOUT + (0.5 * y_accel * t_squared);
        double x_dist = _velocity * sin(_angle) / DIVS_AFTER_BURNOUT + (0.5 * x_accel * t_squared);
        _altitude += y_dist;
        deltaAlt = y_dist;
        _travel += x_dist;
        _velocity += (acc - g) / DIVS_AFTER_BURNOUT;

        //OPT all below 3-6%
        _angle = atan(x_dist/y_dist);

        SLFlightDataPoint *dataPoint = [SLFlightDataPoint new];
        dataPoint->time = _timeIndex;
        dataPoint->vel = _velocity;
        dataPoint->alt = _altitude;
        dataPoint->trav = _travel;
        dataPoint->accel = acc;
        dataPoint->mach = _machNumber;
        dataPoint->drag = drag;

        [self.flightProfile addObject:dataPoint]; //OPT 31%
    } //OPT 10% deallocs?!
}

- (float)velocityAtAltitude:(float)alt{
    if (alt <= 0) return 0;
    NSInteger counter = 0;
    for (NSInteger i = 0; i < [self.flightProfile count]; i++){
        SLFlightDataPoint *flightDataPoint = _flightProfile[i];
        double altAtIndex = flightDataPoint->alt;
        if (altAtIndex > alt){
            counter = i;
            break;
        }
    }
    if ((!counter) || (counter == [_flightProfile count] - 1)) return 0;
    SLFlightDataPoint *prevPoint = _flightProfile[counter-1];
    SLFlightDataPoint *curPoint = _flightProfile[counter];
    double v0 = prevPoint->vel;
    double v1 = curPoint->vel;
    double d0 = prevPoint->alt;
    double d1 = curPoint->alt;
    double slope = (v1 - v0)/(d1 - d0);
    return (v0 + slope * (alt - d0));
}

#pragma mark - dataSource methods

-(SLFlightDataPoint *)maxValues
{
    if (![_flightProfile count]) return [[SLFlightDataPoint alloc] init];
    if (!_maxValues){
        _maxValues = [_flightProfile firstObject];
        for (SLFlightDataPoint *dp in _flightProfile){
            if (dp->alt > _maxValues->alt) _maxValues->alt = dp->alt;
            if (dp->vel > _maxValues->vel) _maxValues->vel = dp->vel;
            if (dp->trav > _maxValues->trav) _maxValues->trav = dp->trav;
            if (dp->accel > _maxValues->accel) _maxValues->accel = dp->accel;
            if (dp->mach > _maxValues->mach) _maxValues->mach = dp->mach;
            if (dp->drag > _maxValues->drag) _maxValues->drag = dp->drag;
        }
    }
    return _maxValues;
}

-(NSString *)rocketName{
    return [self.rocket description];
}

-(NSString *)motorDescription{
    return [self.rocket motorDescription];
}

- (float)apogee{
    SLFlightDataPoint *point = [self.flightProfile lastObject];
    return point->alt;
}

-(float)apogeeAltitude{
    SLFlightDataPoint *point = [self.flightProfile lastObject];

    return point->alt;
}

- (float)fastApogee{
    SLFlightDataPoint *point = [self.flightProfile lastObject];

    //currently this is no different from the slow method, but I hope to speed it up
    //Consider stashing last object whenever it changes? Measure first though.
    return point->alt ;
}

- (float)coastTime{
    return [self burnoutToApogee];
}

-(float)totalTime{
    SLFlightDataPoint *point = [self.flightProfile lastObject];

    return point->time;
}

- (float)burnoutToApogee{
    SLFlightDataPoint *point = [self.flightProfile lastObject];

    return point->time - [self.rocket burnoutTime];
}


-(float)burnoutVelocity{
    return self.brnoutVelocity;
}

-(float)maxVelocity{
//    float mxvel = 0.0;
//    for (SLFlightDataPoint *dataPoint in _flightProfile){
//        if (dataPoint->vel > mxvel){
//            mxvel = dataPoint->vel;
//        }
//    }
//    return mxvel;
    return self.maxValues->vel;
}

-(float)maxAcceleration{
//    float accelMax = 0.0;
//    for (SLFlightDataPoint *arr in _flightProfile){
//        float accel = arr->accel;
//        if (accel > accelMax) accelMax = accel;
//    }
//    return accelMax;
    return self.maxValues->accel;
}

-(float)maxDeceleration{
    float decelMax = 0.0;
    for (SLFlightDataPoint *arr in _flightProfile){
        float accel = arr->accel;
        if (accel < decelMax) decelMax = accel;
    }
    return decelMax;
}

-(float)maxMachNumber{
//    float maxMach = 0.0;
//    for (SLFlightDataPoint *arr in _flightProfile){
//        float mac = arr->mach;
//        if (mac > maxMach) maxMach = mac;
//    }
//    return maxMach;
    return self.maxValues->mach;
}

-(float)maxDrag{
//    float maxDrag = 0.0;
//    for (SLFlightDataPoint *arr in _flightProfile){
//        float drag = arr->drag;
//        if (drag > maxDrag) maxDrag = drag;
//    }
//    return maxDrag;
    return self.maxValues->drag;
}

//These methods are for the plotting of the flight profile. They should run fast enough.  We shall see
//It occurs to me that I should do binary search on the time to improve performance

-(NSInteger)dataIndexForTimeIndex:(float)timeIndex{
    NSInteger pivot = [self.flightProfile count]/2;
    NSInteger move = pivot/2;
    while (move>1) {
        SLFlightDataPoint *point = self.flightProfile[pivot];
        double time = point->time;
        if (time > timeIndex){
            //if the pivot point is AFTER the timeIndex, look behind
            pivot -= move;
            move /= 2;
        }else{
            //look forward
            pivot += move;
            move /= 2;
        }
    }
    return pivot;
}

-(SLFlightDataPoint *)dataAtTime:(float)timeIndex{
    NSInteger i = [self dataIndexForTimeIndex:timeIndex];
    SLFlightDataPoint *dataPoint = self.flightProfile[i];
    return dataPoint;
}

// This next method is for the rapid updates necessary for the drawRect routine in the animated view

-(float)quickFFVelocityAtLaunchAngle:(float)angle andGuideLength:(float)length{
    float g = GRAV_ACCEL * cosf(angle);
    float dist = 0.0;   // This quick calculation ignores the difference between distance travelled and altitude
    float timedex = 0.0;
    float v = 0.0;
    //This will loop until the rocket JUST leaves the launch guide - close enough for display purposes
    while (dist < length) {
        timedex += 1.0/DIVS_DURING_BURN;
        float mass = [_rocket massAtTime:timedex];
        float a = [_rocket thrustAtTime:timedex]/mass - g - [self dragAtVelocity:v time: timedex andAltitude:dist]/mass;
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
    self.maxValues = nil;
}

@end
