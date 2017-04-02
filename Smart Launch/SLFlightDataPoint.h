//
//  SLFlightDataPoint.h
//  Smart Launch
//
//  Created by Stephen Christopher on 2/12/14.
//  Copyright (c) 2014 J. HOWARD SMART. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLFlightDataPoint : NSObject {
    @public
    double time;
    double vel;
    double alt;
    double trav;
    double accel;
    double mach;
    double drag;
}

-(void)updateTime:(double)time velocity:(double)vel altitude:(double)alt travel:(double)trav accel:(double)accel mach:(double)mach andDrag:(double)drag;

@end
