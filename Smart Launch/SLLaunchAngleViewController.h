//
//  Smart Launch
//  Launch Angle visual aid using accelerometer to plumb the angle
//
//  Created by J. Howard Smart on 2/20/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLSimulationDelegate.h"

@interface SLLaunchAngleViewController : UIViewController<UIAccelerometerDelegate>

@property (nonatomic, weak) id <SLSimulationDelegate> delegate;

@end
