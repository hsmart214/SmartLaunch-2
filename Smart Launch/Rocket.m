//
//  Rocket.m
//  LaunchSafeRockets
//
//  Created by J. Howard Smart on 4/28/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import "Rocket.h"
#import "SLDefinitions.h"


@implementation Rocket

@synthesize name = _name;
@synthesize length = _length;
@synthesize diameter = _diameter;
@synthesize cd = _cd;
@synthesize motorSize = _motorSize;
@synthesize mass = _mass;
@synthesize kitName = _kitName;
@synthesize manufacturer = _manufacturer;

- (Rocket *)copyWithZone: (NSZone *)zone{
    return [Rocket rocketWithRocketDict:self.rocketPropertyList];
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
    return self;
}

-(Rocket *)init{
    NSDictionary *rocketProperties = [NSDictionary dictionary];
    self = [self initWithProperties:rocketProperties];
    return self;
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

    return rocketProperties;
}

+(Rocket *)rocketWithRocketDict:(NSDictionary *)rocketDict{
    Rocket *rocket = [[Rocket alloc] initWithProperties:rocketDict];
    return rocket;
}
@end
