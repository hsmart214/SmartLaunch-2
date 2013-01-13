//
//  Rocket.h
//  Smart Launch
//
//  Created by J. Howard Smart on 4/28/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Rocket : NSObject<NSCopying>

@property (nonatomic, strong) NSString * name;          //user's name for the rocket
@property (nonatomic, strong) NSNumber * length;        //meters float
@property (nonatomic, strong) NSNumber * diameter;      //meters float
@property (nonatomic, strong) NSNumber * cd;            //dimensionless float
@property (nonatomic, strong) NSNumber * motorSize;     //this one is an integer number of millimeters
@property (nonatomic, strong) NSNumber * mass;          //kilograms float
@property (nonatomic, strong) NSString * kitName;       //manufacturer's name for the kit
@property (nonatomic, strong) NSString * manufacturer;  //company that made the kit (if any)
@property (nonatomic, strong) NSArray *recordedFlights; //array of NSDictionary* plists of flight information

-(NSDictionary *)rocketPropertyList;

+(Rocket *)rocketWithRocketDict:(NSDictionary *)rocketDict;

-(Rocket *)copyWithZone:(NSZone *)zone;

+(Rocket *)defaultRocket;

@end
