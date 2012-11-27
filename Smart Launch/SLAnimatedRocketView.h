//
//  SLAnimatedRocketView.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/25/12.
//  Copyright (c) 2012 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SLAnimatedRocketView : UIView

-(void)tiltRocketToAngle:(float)angle;
-(void)UpdateVectorsWithRocketVelocity:(float)rocketVelocity
                       andWindVelocity:(float)windVelocity;
@end