//
//  SLSimulationDelegate.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/26/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Rocket.h"
#import "RocketMotor.h"

@protocol SLSimulationDelegate <NSObject>

@optional
-(void)sender:(id)sender didChangeSimSettings:(NSDictionary *)settings withUpdate:(BOOL) update;
-(void)sender:(id)sender didChangeLaunchAngle:(NSNumber *)launchAngle;
-(void)sender:(id)sender didChangeRocket:(Rocket *)rocket;
-(void)sender:(id)sender didChangeRocketMotor:(RocketMotor *)motor;
-(void)dismissModalViewController;

@end

@protocol SLSimulationDataSource <NSObject>

@optional

-(NSMutableDictionary *)simulationSettings;
-(NSNumber *)freeFlightVelocity;
-(NSNumber *)freeFlightAoA;
-(NSNumber *)windVelocity;
-(NSNumber *)launchAngle;
-(NSNumber *)launchGuideLength;
-(NSNumber *)launchSiteAltitude;
-(enum LaunchDirection)launchGuideDirection;
-(float)quickFFVelocityAtAngle:(float)angle andGuideLength:(float)length;

@end