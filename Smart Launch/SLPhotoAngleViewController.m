//
//  SLPhotoAngleViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 8/5/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLPhotoAngleViewController.h"
#import "CoreMotion/CoreMotion.h"

#define VIEW_FINDER_IMAGE_FILENAME @"Viewfinder"
#define ANGLE_WARNING_IMAGE_FILENAME @"AngleWarning"
#define ACCEPT_BUTTON_FILENAME @"AcceptButton"
#define ACCEPT_SELECTED_FILENAME @"AcceptButtonSelected"
#define CANCEL_BUTTON_FILENAME @"CancelButton"
#define CANCEL_SELECTED_FILENAME @"CancelButtonSelected"
#define ANGLE_WARNING_SIZE 172
#define ANGLE_VIEW_FONT_SIZE 33
#define BUTTON_WIDTH 120
#define BUTTON_HEIGHT 120

@interface SLPhotoAngleViewController ()

@property (nonatomic, strong) UIAccelerometer *accelerometer;
@property (nonatomic) UIAccelerationValue xAccel;
@property (nonatomic) UIAccelerationValue yAccel;
@property (nonatomic) UIAccelerationValue zAccel;
@property (nonatomic, strong) UIView *angleView;
@property (nonatomic, strong) UIImageView *warningView;
@property (nonatomic, strong) UILabel *angleLabel;
@property (nonatomic, strong) UIButton *acceptButton;
@property (nonatomic, strong) UIButton *cancelButton;

@end

@implementation SLPhotoAngleViewController

- (UIAccelerometer *)accelerometer{
    if (!_accelerometer){
        _accelerometer = [UIAccelerometer sharedAccelerometer];
    }
    return _accelerometer;
}

#pragma mark - UIAccelerometer delegate

//Filtering constants
#define UPDATE_INTERVAL 0.1
#define FILTER_CONSTANT 0.08 //smaller number gives smoother, slower response

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)accel{
    
    //Low-pass filter for accelerometer measurements
    CGFloat alpha  = FILTER_CONSTANT;
    self.xAccel = accel.x * alpha + self.xAccel * (1.0 - alpha);
    self.yAccel = accel.y * alpha + self.yAccel * (1.0 - alpha);
    self.zAccel = accel.z * alpha + self.zAccel * (1.0 - alpha);
    
    //Now that they are filtered we can use the results to display the launch angle
    //The disabled lines add the third dimension and result in some unhappy display problems.  Hmm...
    CGFloat xyAngle;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){   //iPad
        xyAngle = atan(self.yAccel/self.xAccel) - self.yxCalibrationAngle;
        if (self.xAccel > 0) xyAngle = -xyAngle;
    }else{    // iPhone
        xyAngle = atan(self.xAccel/self.yAccel) - self.xyCalibrationAngle;
    }
    //    CGFloat yzAngle = atan(self.zAccel/self.yAccel) - self.yzCalibrationAngle;
    CGFloat angle = xyAngle;
    //    CGFloat angle = atanf(sqrtf(tanf(xyAngle)*tanf(xyAngle)+tanf(yzAngle)*tanf(yzAngle)));
    self.angleLabel.text = [NSString stringWithFormat:@"%1.1f°", fabsf(angle)];
    if (fabsf(angle)/DEGREES_PER_RADIAN > MAX_LAUNCH_GUIDE_ANGLE){
        [self.warningView setHidden:NO];
        [self.acceptButton setHidden:YES];
    }else{
        [self.warningView setHidden:YES];
        [self.acceptButton setHidden:NO];
    }
}

- (void)startMotionUpdates{
    NSTimeInterval updateInterval = UPDATE_INTERVAL;
    [self.accelerometer setDelegate:self];
    [self.accelerometer setUpdateInterval:updateInterval];
}

- (void)stopMotionUpdates{
    self.accelerometer.delegate=nil;
}

#pragma mark - UIImagePickerControllerDelegate

- (BOOL)startCameraControllerFromViewController: (UIViewController*) controller
                                  usingDelegate: (id <UIImagePickerControllerDelegate,
                                                  UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    if (!cameraUI) return NO;
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;

    cameraUI.allowsEditing = NO;
    
    cameraUI.delegate = delegate;
    cameraUI.showsCameraControls = NO;
    
    [controller presentViewController:cameraUI animated:NO completion:nil]; // looks better not animated, besides
                                                                    // if animated, generates "unbalanced calls" error
    cameraUI.cameraOverlayView = self.angleView;
    self.angleView.opaque = NO;
    return YES;
}

- (UIView *)angleView{
    if (!_angleView){
        _angleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        UIImageView * viewFinderView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
//        NSString *viewFinderFileName = [[NSBundle mainBundle] pathForResource: VIEW_FINDER_IMAGE_FILENAME ofType:@"png"];
//        UIImage * viewFinderImage = [[UIImage alloc] initWithContentsOfFile:viewFinderFileName];
        UIImage * viewFinderImage = [UIImage imageNamed:VIEW_FINDER_IMAGE_FILENAME];

        [viewFinderView setImage:viewFinderImage];
        [_angleView addSubview:self.warningView];
        [self.warningView setHidden:YES];
        [_angleView addSubview:viewFinderView];
        
        self.angleLabel = [[UILabel alloc] initWithFrame:CGRectMake(108, 20, 105, 58)];
        UIFont *newFont =[self.angleLabel.font fontWithSize:ANGLE_VIEW_FONT_SIZE];
        
        [self.angleLabel setFont:newFont];
        [self.angleLabel setNumberOfLines:1];
        [self.angleLabel setTextColor:[UIColor whiteColor]];
        [self.angleLabel setTextAlignment:NSTextAlignmentCenter];
        self.angleLabel.text = @"0.0°";
        [self.angleLabel setBackgroundColor:[UIColor clearColor]];
        [_angleView addSubview: self.angleLabel];
        
        //make the accept button image
        
        //NSString *acceptFilename = [[NSBundle mainBundle] pathForResource: ACCEPT_BUTTON_FILENAME ofType:@"png"];
        UIImage *acceptButtonImage = [UIImage imageNamed:ACCEPT_BUTTON_FILENAME];
        //NSString *acceptSelectedFilename = [[NSBundle mainBundle] pathForResource: ACCEPT_SELECTED_FILENAME ofType:@"png"];
        UIImage *acceptSelectedImage = [UIImage imageNamed:ACCEPT_SELECTED_FILENAME];
        
        CGRect buttonFrame = CGRectMake(self.view.bounds.size.width/2 + BUTTON_HEIGHT/4, self.view.bounds.size.height - BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT);
        self.acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.acceptButton setFrame:buttonFrame];
        [self.acceptButton setTitle:@"Accept" forState:UIControlStateNormal];
        [self.acceptButton addTarget:self action:@selector(acceptAngle) forControlEvents:UIControlEventTouchUpInside];
        [self.acceptButton setHidden:NO];
        [self.acceptButton setUserInteractionEnabled:YES];
        [self.acceptButton setImage:acceptButtonImage forState:UIControlStateNormal];
        [self.acceptButton setImage:acceptSelectedImage forState:UIControlStateHighlighted];
        [_angleView addSubview:self.acceptButton];
        
        //make the cancel button image
        
        //NSString *cancelFilename = [[NSBundle mainBundle] pathForResource: CANCEL_BUTTON_FILENAME ofType:@"png"];
        UIImage *cancelButtonImage = [UIImage imageNamed:CANCEL_BUTTON_FILENAME];
        //NSString *cancelSelectedFilename = [[NSBundle mainBundle] pathForResource: CANCEL_SELECTED_FILENAME ofType:@"png"];
        UIImage *cancelSelectedImage = [UIImage imageNamed:CANCEL_SELECTED_FILENAME];

        buttonFrame = CGRectMake(self.view.bounds.size.width/2 - BUTTON_WIDTH - BUTTON_HEIGHT/4, self.view.bounds.size.height - BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT);
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cancelButton setFrame:buttonFrame];
        [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelButton setHidden:NO];
        [self.cancelButton setUserInteractionEnabled:YES];
        [self.cancelButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self.cancelButton setImage:cancelButtonImage forState:UIControlStateNormal];
        [self.cancelButton setImage:cancelSelectedImage forState:UIControlStateHighlighted];

        [_angleView addSubview:self.cancelButton];

    }
    return _angleView;
}

- (UIImageView *)warningView{
    if (!_warningView){
        CGFloat x, y;
        x = self.view.bounds.size.width/2 - ANGLE_WARNING_SIZE/2;
        y = self.view.bounds.size.height/2 - ANGLE_WARNING_SIZE/2 + 5;
        _warningView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, ANGLE_WARNING_SIZE, ANGLE_WARNING_SIZE)];
        //NSString *warningFileName = [[NSBundle mainBundle] pathForResource: ANGLE_WARNING_IMAGE_FILENAME ofType:@"png"];
        UIImage *warningImage = [UIImage imageNamed:ANGLE_WARNING_IMAGE_FILENAME];
        [_warningView setImage:warningImage];
    }
    return _warningView;
}

#pragma mark - SLPhotoAngleViewDelegate methods

- (void)acceptAngle{
    float radians = [self.angleLabel.text floatValue]/ DEGREES_PER_RADIAN;
    if (radians > MAX_LAUNCH_GUIDE_ANGLE){
        radians = MAX_LAUNCH_GUIDE_ANGLE;
    }
    NSNumber *angle = @(radians);
    [self.delegate sender:self didChangeLaunchAngle:angle];
    self.accelerometer.delegate = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)cancel{
    self.accelerometer.delegate = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self startCameraControllerFromViewController:self usingDelegate:self];
    [self startMotionUpdates];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)dealloc{
    self.accelerometer.delegate = nil;
    self.accelerometer = nil;
    self.cancelButton = nil;
    self.acceptButton = nil;
    self.angleView = nil;
    self.angleLabel = nil;
    self.warningView = nil;

}
@end
