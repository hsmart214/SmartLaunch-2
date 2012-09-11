//
//  Rocket.h
//  LaunchSafeRockets
//
//  Created by J. Howard Smart on 4/28/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ROCKET_NAME_KEY @"RocketName"
#define ROCKET_LENGTH_KEY @"RocketLength"
#define ROCKET_DIAM_KEY @"RocketDiameter"
#define ROCKET_CD_KEY @"RocketCD"
#define ROCKET_MOTORSIZE_KEY @"RocketMotorSize"
#define ROCKET_MASS_KEY @"RocketMass"
#define ROCKET_KITNAME_KEY @"RocketKitName"
#define ROCKET_MAN_KEY @"RocketManufacturer"

@interface Rocket : NSObject<NSCopying>

@property (nonatomic, retain) NSString * name;          //user's name for the rocket
@property (nonatomic, retain) NSNumber * length;        //meters
@property (nonatomic, retain) NSNumber * diameter;      //meters
@property (nonatomic, retain) NSNumber * cd;            //dimensionless
@property (nonatomic, retain) NSNumber * motorSize;     //this one is an integer number of millimeters
@property (nonatomic, retain) NSNumber * mass;          //kilograms
@property (nonatomic, retain) NSString * kitName;       //manufacturer's name for the kit
@property (nonatomic, retain) NSString * manufacturer;  //company that made the kit (if any)

-(NSDictionary *)rocketPropertyList;

+(Rocket *)rocketWithRocketDict:(NSDictionary *)rocketDict;

- (Rocket *)copyWithZone:(NSZone *)zone;

+(Rocket *)defaultRocket;

@end
