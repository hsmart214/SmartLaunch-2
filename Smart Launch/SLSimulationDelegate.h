//
//  SLSimulationDelegate.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/26/12.
//  Copyright (c) 2012 All rights reserved.
//

@import Foundation;
#import "Rocket.h"
#import "RocketMotor.h"

@protocol SLSimulationDelegate <NSObject>

@optional
-(void)sender:(id)sender didChangeSimSettings:(NSDictionary *)settings withUpdate:(BOOL) update;
-(void)sender:(id)sender didChangeLaunchAngle:(NSNumber *)launchAngle;
-(void)sender:(id)sender didChangeRocket:(Rocket *)rocket;
// this is an array to accomodate clusters - an array of NSDictionary* with counts and motorDicts
-(void)sender:(id)sender didChangeRocketMotor:(NSArray *)motorPlist;
-(void)didChangeUnitPrefs:(id)sender;
-(void)dismissModalViewController;
-(BOOL)shouldAllowSimulationUpdates;

@end

@protocol SLSimulationDataSource <NSObject>

@optional

-(NSMutableDictionary *)simulationSettings;
-(float)freeFlightVelocity;
-(float)freeFlightAoA;
-(float)windVelocity;
-(float)launchAngle;
-(float)launchGuideLength;
-(float)launchSiteAltitude;
-(LaunchDirection)launchGuideDirection;
-(float)quickFFVelocityAtAngle:(float)angle andGuideLength:(float)length;
-(NSString *)avatarName;
@end