//
//  SLPhotoAngleViewController.h
//  Snoopy
//
//  Created by J. HOWARD SMART on 8/5/12.
//
//

#import <UIKit/UIKit.h>
#import "SLSimulationDelegate.h"
#import "SLPhotoAngleFinderDelegate.h"

@interface SLPhotoAngleViewController : UIViewController <UIAccelerometerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) id <SLSimulationDelegate> delegate;
@property (nonatomic) CGFloat xyCalibrationAngle;
@property (nonatomic) CGFloat yzCalibrationAngle;

@end
