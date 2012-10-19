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

@property (nonatomic, strong) NSString * name;          //user's name for the rocket
@property (nonatomic, strong) NSNumber * length;        //meters
@property (nonatomic, strong) NSNumber * diameter;      //meters
@property (nonatomic, strong) NSNumber * cd;            //dimensionless
@property (nonatomic, strong) NSNumber * motorSize;     //this one is an integer number of millimeters
@property (nonatomic, strong) NSNumber * mass;          //kilograms
@property (nonatomic, strong) NSString * kitName;       //manufacturer's name for the kit
@property (nonatomic, strong) NSString * manufacturer;  //company that made the kit (if any)

-(NSDictionary *)rocketPropertyList;

+(Rocket *)rocketWithRocketDict:(NSDictionary *)rocketDict;

- (Rocket *)copyWithZone:(NSZone *)zone;

+(Rocket *)defaultRocket;

@end
