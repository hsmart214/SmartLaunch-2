//
//  SLAnimatedRocketView.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/25/12.
//  Copyright (c) 2012 All rights reserved.
//

@import UIKit;
#import "SLSimulationDelegate.h"

@interface SLAnimatedRocketView : UIView

@property (nonatomic, strong) NSString* avatar;

-(void)tiltRocketToAngle:(float)angle;
-(void)UpdateVectorsWithRocketVelocity:(float)rocketVelocity
                       andWindVelocity:(float)windVelocity;
-(void)startFresh;
@end
