//
//  SLFlightDataPoint.m
//  Smart Launch
//
//  Created by Stephen Christopher on 2/12/14.
//  Copyright (c) 2014 J. HOWARD SMART. All rights reserved.
//

#import "SLFlightDataPoint.h"

@implementation SLFlightDataPoint

-(NSString *)description{
    return [NSString stringWithFormat:@"Time: %1.2fs Alt: %1.1fm Vel: %1.1fm/s", self->time, self->alt, self->vel];
}

@end
