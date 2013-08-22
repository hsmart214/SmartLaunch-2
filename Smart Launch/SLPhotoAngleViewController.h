//
//  SLPhotoAngleViewController.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 8/5/12.
//  Copyright (c) 2012 All rights reserved.
//

@import UIKit;
#import "SLSimulationDelegate.h"
#import "SLPhotoAngleFinderDelegate.h"

@interface SLPhotoAngleViewController : UIViewController <UIAccelerometerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) id <SLSimulationDelegate> delegate;
@property (nonatomic) CGFloat xyCalibrationAngle;
@property (nonatomic) CGFloat yxCalibrationAngle;
@property (nonatomic) CGFloat yzCalibrationAngle;

@end
