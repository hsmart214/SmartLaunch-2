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

-(CGFloat)motorThrustCurveViewDataValueRange: (SLMotorThrustCurveView *)sender;
-(CGFloat)motorThrustCurveViewTimeValueRange:(SLMotorThrustCurveView *)sender;
-(CGFloat)motorThrustCurveView:(SLMotorThrustCurveView *)thrustCurveView dataValueForTimeIndex:(CGFloat)timeIndex;

@end

@interface SLMotorThrustCurveView : UIView

@property (nonatomic, weak) id<SLMotorThrustCurveViewDataSource> dataSource;

@end
