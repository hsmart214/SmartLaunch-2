//
//  SLSimulationDelegate.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/26/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Rocket.h"
#import "RocketMotor.h"
#import "SLDefinitions.h"

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

-(NSNumber *)freeFlightVelocity;
-(NSNumber *)freeFlightAoA;
-(NSNumber *)windVelocity;
-(NSNumber *)launchAngle;
-(enum LaunchDirection)launchGuideDirection;

@end