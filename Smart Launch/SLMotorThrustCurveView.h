//
//  SLMotorThrustCurveView.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RocketMotor.h"

@class SLMotorThrustCurveView;


@protocol SLMotorThrustCurveViewDataSource <NSObject>

-(CGFloat)dataValueRange:(SLMotorThrustCurveView *) sender;
-(CGFloat)timeValueRange:(SLMotorThrustCurveView *)sender;
-(CGFloat)dataValueForTimeIndex:(CGFloat)time forView:(SLMotorThrustCurveView *)sender;

@end

@interface SLMotorThrustCurveView : UIView

@property (nonatomic, weak) id<SLMotorThrustCurveViewDataSource> dataSource;

@end
