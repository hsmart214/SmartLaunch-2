//
//  SLPhysicsModel.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//
//  As much as possible, all internal calculations will be carried out using the metric system.
//  The user will be able to localize the interface to the desired units for display purposes.

#import <Foundation/Foundation.h>
#import "RocketMotor.h"
#import "Rocket.h"


@interface SLPhysicsModel : NSObject

@property (nonatomic) float launchGuideLength;
@property (nonatomic) float launchGuideAngle;
@property (nonatomic) enum LaunchDirection LaunchGuideDirection;
@property (nonatomic) float windVelocity;
@property (nonatomic, strong) RocketMotor *motor;
@property (nonatomic, strong) Rocket *rocket;
@property (nonatomic) float launchAltitude;
@property (nonatomic, readonly) NSUInteger version;


/* The first public method returns the velocity that the rocket will attain at the end of the launch guide */

- (double) velocityAtEndOfLaunchGuide;
- (float) maximumVelocity;

/* This will give the resulting angle of attack of the rocket in the air mass at when it leaves the launch guide */

- (float) freeFlightAngleOfAttack;          // AOA when the rocket leaves the launch guide - RADIANS

- (double)velocityAtAltitude:(double)alt;   // from the profile, returns the velocity (METERS/SEC) at a given altitude (METERS)

- (void)resetFlight;                        // reset the flight profile

- (double)apogee;                           // maximum altitude in METERS
- (float)fastApogee;                        // to be used in the estimations for calculating the best Cd

- (double)burnoutToApogee;                  // SECONDS from burnout to apogee - the ideal motor delay

- (float)quickFFVelocityAtLaunchAngle:(float)angle andGuideLength:(float)length;
                                            // a constructed array of time, altitude, velocity, acceleration - NSArray of NSArray
                                            // for use in graphing the flightProfile
- (NSArray *)flightDataWithTimeIncrement: (float)increment;  

@end
