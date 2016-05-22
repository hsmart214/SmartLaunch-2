//
//  SLClusterMotor.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/12/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

//This is a lightweight immutable wrapper for a list of motor plists, just to give a few common calculation functions

@interface SLClusterMotor : NSObject<NSCopying>

@property (nonatomic, readonly)float totalBurnLength;
@property (nonatomic, readonly)float totalImpulse;
@property (nonatomic, readonly)float propellantMass;
@property (nonatomic, readonly)float mass;
@property (nonatomic, readonly)float peakInitialThrust;
@property (nonatomic, readonly)float truePeakThrust;
@property (nonatomic, readonly)NSUInteger diameter;
@property (nonatomic, readonly)NSString *impulseClass;
@property (nonatomic, readonly)NSString *fractionalImpulseClass;
@property (nonatomic, readonly)NSString *longDescription;
@property (nonatomic, readonly)NSUInteger motorCount;
@property (nonatomic, readonly)NSString *firstMotorName;
@property (nonatomic, readonly)NSString *firstMotorManufacturer;

-(id)initWithMotorLoadout:(NSArray *)motorLoadout;
-(float)thrustAtTime:(float)time;

+(double)totalImpulseFromFlightSettings:(NSDictionary *)settings;
@end
