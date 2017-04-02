//
//  SLFlightDataPoint.m
//  Smart Launch
//
//  Created by Stephen Christopher on 2/12/14.
//  Copyright (c) 2014 J. HOWARD SMART. All rights reserved.
//

#import "SLFlightDataPoint.h"

@implementation SLFlightDataPoint

-(void)updateTime:(double)t velocity:(double)v altitude:(double)a travel:(double)tr accel:(double)acc mach:(double)m andDrag:(double)d
{
    alt = a;
    vel = v;
    alt = a;
    trav = tr;
    accel = acc;
    mach = m;
    drag = d;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"Time: %1.2fs Alt: %1.1fm Vel: %1.1fm/s", self->time, self->alt, self->vel];
}

@end
