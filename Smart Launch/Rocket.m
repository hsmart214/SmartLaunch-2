//
//  Rocket.m
//  Smart Launch
//
//  Created by J. Howard Smart on 4/28/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "Rocket.h"

@implementation Rocket

- (void)clearFlights{
    self.recordedFlights = nil;
}

- (void)addFlight:(NSDictionary *)flightData{
    NSMutableArray *newFlights = [self.recordedFlights mutableCopy];
    if (!newFlights) newFlights = [NSMutableArray array];
    [newFlights addObject:flightData];
    self.recordedFlights = [newFlights copy];
}

- (Rocket *)copyWithZone: (NSZone *)zone{
    return [Rocket rocketWithRocketDict:self.rocketPropertyList];
}

- (Rocket *)copy{
    return [self copyWithZone:nil];
}

- (NSNumber *)cd{
    if (!_cd){
        _cd = @(DEFAULT_CD);
    }
    return _cd;
}

-(Rocket *)initWithProperties:(NSDictionary *)rocketProperties{
    self = [super init];
    self.name = rocketProperties[ROCKET_NAME_KEY];
    self.length = rocketProperties[ROCKET_LENGTH_KEY];
    self.diameter = rocketProperties[ROCKET_DIAM_KEY];
    self.cd = rocketProperties[ROCKET_CD_KEY];
    self.motorSize = rocketProperties[ROCKET_MOTORSIZE_KEY];
    self.mass = rocketProperties[ROCKET_MASS_KEY];
    self.kitName = rocketProperties[ROCKET_KITNAME_KEY];
    self.manufacturer = rocketProperties[ROCKET_MAN_KEY];
    self.recordedFlights = rocketProperties[ROCKET_RECORDED_FLIGHTS_KEY];
    return self;
}

-(Rocket *)init{
    NSDictionary *rocketProperties = @{};
    self = [self initWithProperties:rocketProperties];
    return self;
}

- (void)dealloc{
    self.name = nil;
    self.length = nil;
    self.diameter = nil;
    self.cd = nil;
    self.motorSize = nil;
    self.mass = nil;
    self.kitName = nil;
    self.manufacturer = nil;
}

-(NSDictionary *)rocketPropertyList{
    NSMutableDictionary *rocketProperties = [NSMutableDictionary dictionary];
    if (self.name) rocketProperties[ROCKET_NAME_KEY] = self.name;
    if (self.length) rocketProperties[ROCKET_LENGTH_KEY] = self.length;
    if (self.diameter) rocketProperties[ROCKET_DIAM_KEY] = self.diameter;
    if (self.cd) rocketProperties[ROCKET_CD_KEY] = self.cd;
    if (self.motorSize) rocketProperties[ROCKET_MOTORSIZE_KEY] = self.motorSize;
    if (self.mass) rocketProperties[ROCKET_MASS_KEY] = self.mass;
    if (self.kitName) rocketProperties[ROCKET_KITNAME_KEY] = self.kitName;
    if (self.manufacturer) rocketProperties[ROCKET_MAN_KEY] = self.manufacturer;
    if (self.recordedFlights) rocketProperties[ROCKET_RECORDED_FLIGHTS_KEY] = self.recordedFlights;
    return rocketProperties;
}

+(Rocket *)rocketWithRocketDict:(NSDictionary *)rocketDict{
    Rocket *rocket = [[Rocket alloc] initWithProperties:rocketDict];
    return rocket;
}

+(Rocket *)defaultRocket{
    NSDictionary *goblinProperties = @{ROCKET_NAME_KEY: @"Goblin",
                                      ROCKET_KITNAME_KEY: @"Goblin",
                                      ROCKET_MAN_KEY: @"Estes",
                                      ROCKET_DIAM_KEY: @0.033655f,
                                      ROCKET_LENGTH_KEY: @0.36322f,
                                      ROCKET_MASS_KEY: @0.034f,
                                      ROCKET_MOTORSIZE_KEY: @24,
                                      ROCKET_CD_KEY: @(DEFAULT_CD)};

    return [[Rocket alloc] initWithProperties:goblinProperties];
}
@end
