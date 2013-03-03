//
//  SLCurveGraphView.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Modified from SLMotorThrustCurveView.h 3/3/13 to make it more obviously generic and reusable
//  Copyright (c) 2012 All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RocketMotor.h"

@class SLCurveGraphView;

@protocol SLCurveGraphViewDelegate <NSObject>

@optional

-(BOOL)shouldDisplayMachOneLine:(SLCurveGraphView *)sender;
-(NSUInteger)numberOfVerticalDivisions:(SLCurveGraphView *)sender;

@end

@protocol SLCurveGraphViewDataSource <NSObject>

-(CGFloat)curveGraphViewDataValueRange: (SLCurveGraphView *)sender;
-(CGFloat)curveGraphViewDataValueMinimumValue:(SLCurveGraphView *)sender;
-(CGFloat)curveGraphViewTimeValueRange:(SLCurveGraphView *)sender;
-(CGFloat)curveGraphView:(SLCurveGraphView *)sender dataValueForTimeIndex:(CGFloat)timeIndex;

@end

@interface SLCurveGraphView : UIView

@property (nonatomic, weak) id<SLCurveGraphViewDelegate>delegate;
@property (nonatomic, weak) id<SLCurveGraphViewDataSource> dataSource;

-(void)setVerticalUnits:(NSString *)units withFormat:(NSString *)formatString;
-(void)resetAxes;       // this is called when updating to a different graph without leaving the view

@end
