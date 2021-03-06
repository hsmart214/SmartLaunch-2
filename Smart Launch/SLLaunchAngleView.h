//
//  SLLaunchAngleView.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

@import UIKit;

@class SLLaunchAngleView;

@protocol SLLaunchAngleViewDataSource <NSObject>

-(CGFloat)angleForLaunchAngleView:(SLLaunchAngleView *)sender;

@end

@interface SLLaunchAngleView : UIView

@property (nonatomic,weak) id <SLLaunchAngleViewDataSource> dataSource;

@end
