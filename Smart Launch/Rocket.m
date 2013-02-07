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
        _cd = [NSNumber numberWithFloat:DEFAULT_CD];
    }
    return _cd;
}

-(Rocket *)initWithProperties:(NSDictionary *)rocketProperties{
    self = [super init];
    self.name = [rocketProperties objectForKey:ROCKET_NAME_KEY];
    self.length = [rocketProperties objectForKey:ROCKET_LENGTH_KEY];
    self.diameter = [rocketProperties objectForKey:ROCKET_DIAM_KEY];
    self.cd = [rocketProperties objectForKey:ROCKET_CD_KEY];
    self.motorSize = [rocketProperties objectForKey:ROCKET_MOTORSIZE_KEY];
    self.mass = [rocketProperties objectForKey:ROCKET_MASS_KEY];
    self.kitName = [rocketProperties objectForKey:ROCKET_KITNAME_KEY];
    self.manufacturer = [rocketProperties objectForKey:ROCKET_MAN_KEY];
    self.recordedFlights = [rocketProperties objectForKey:ROCKET_RECORDED_FLIGHTS_KEY];
    return self;
}

-(Rocket *)init{
    NSDictionary *rocketProperties = [NSDictionary dictionary];
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
    if (self.name) [rocketProperties setObject:self.name forKey:ROCKET_NAME_KEY];
    if (self.length) [rocketProperties setObject:self.length forKey:ROCKET_LENGTH_KEY];
    if (self.diameter) [rocketProperties setObject:self.diameter forKey:ROCKET_DIAM_KEY];
    if (self.cd) [rocketProperties setObject:self.cd forKey:ROCKET_CD_KEY];
    if (self.motorSize) [rocketProperties setObject:self.motorSize forKey:ROCKET_MOTORSIZE_KEY];
    if (self.mass) [rocketProperties setObject:self.mass forKey:ROCKET_MASS_KEY];
    if (self.kitName) [rocketProperties setObject:self.kitName forKey:ROCKET_KITNAME_KEY];
    if (self.manufacturer) [rocketProperties setObject:self.manufacturer forKey:ROCKET_MAN_KEY];
    if (self.recordedFlights) rocketProperties[ROCKET_RECORDED_FLIGHTS_KEY] = self.recordedFlights;
    return rocketProperties;
}

+(Rocket *)rocketWithRocketDict:(NSDictionary *)rocketDict{
    Rocket *rocket = [[Rocket alloc] initWithProperties:rocketDict];
    return rocket;
}

+(Rocket *)defaultRocket{
    NSDictionary *goblinProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"Goblin", ROCKET_NAME_KEY,
                                      @"Goblin", ROCKET_KITNAME_KEY,
                                      @"Estes", ROCKET_MAN_KEY,
                                      [NSNumber numberWithFloat:0.033655], ROCKET_DIAM_KEY,
                                      [NSNumber numberWithFloat:0.36322], ROCKET_LENGTH_KEY,
                                      [NSNumber numberWithFloat:0.034], ROCKET_MASS_KEY,
                                      [NSNumber numberWithInteger:24], ROCKET_MOTORSIZE_KEY,
                                      [NSNumber numberWithFloat:DEFAULT_CD], ROCKET_CD_KEY, nil];

    return [[Rocket alloc] initWithProperties:goblinProperties];
}
@end
