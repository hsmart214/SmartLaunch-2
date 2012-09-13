//
//  Launch Angle visual representation
//  Smart Launch
//
//  Created by J. Howard Smart on 2/19/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import "SLLaunchAngleViewController.h"
#import "SLLaunchAngleView.h"
#import "CoreMotion/CoreMotion.h"
#import "SLDefinitions.h"
#import "SLPhotoAngleViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define TOLERANCE 0.001

@interface SLLaunchAngleViewController() <SLLaunchAngleViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *angleLabel;
@property (nonatomic, weak) IBOutlet SLLaunchAngleView *angleView;
@property (weak, nonatomic) IBOutlet UISlider *angleSlider;
@property (nonatomic, strong) UIAccelerometer *accelerometer;
@property (nonatomic) UIAccelerationValue xAccel;
@property (nonatomic) UIAccelerationValue yAccel;
@property (nonatomic) UIAccelerationValue zAccel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *motionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *calibrateButton;
@property (nonatomic) CGFloat xyCalibrationAngle;
@property (nonatomic) CGFloat yzCalibrationAngle;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;

@end

@implementation SLLaunchAngleViewController

@synthesize angleLabel = _angleLabel;
@synthesize angleView = _angleView;
@synthesize angleSlider = _angleSlider;
@synthesize accelerometer = _accelerometer;
@synthesize xAccel = _xAccel;
@synthesize yAccel = _yAccel;
@synthesize zAccel = _zAccel;
@synthesize motionButton = _motionButton;
@synthesize calibrateButton = _calibrateButton;
@synthesize xyCalibrationAngle = _xyCalibrationAngle;
@synthesize yzCalibrationAngle = _yzCalibrationAngle;
@synthesize cameraButton = _cameraButton;
@synthesize delegate = _delegate;

#pragma mark - Constant declarations

#define XY_CAL_KEY @"com.smartsoftware.launchsafe.xyCalibrationValue"
#define YZ_CAL_KEY @"com.smartsoftware.launchsafe.yzCalibrationValue"

- (UIAccelerometer *)accelerometer{
    if (!_accelerometer){
        _accelerometer = [UIAccelerometer sharedAccelerometer];
    }
    return _accelerometer;
}


#pragma mark - UIAccelerometer delegate

//Filtering constants
#define UPDATE_INTERVAL 0.05
#define FILTER_CONSTANT 0.1 //smaller number gives smoother, slower response

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)accel{
    
    //Low-pass filter for accelerometer measurements
    CGFloat alpha  = FILTER_CONSTANT;
    self.xAccel = accel.x * alpha + self.xAccel * (1.0 - alpha);
    self.yAccel = accel.y * alpha + self.yAccel * (1.0 - alpha);
    self.zAccel = accel.z * alpha + self.zAccel * (1.0 - alpha);
    
    //Now that they are filtered we can use the results to display the launch angle
    //The disabled lines add the third dimension and result in some unhappy display problems.  Hmm...
    
    CGFloat xyAngle = atan(self.xAccel/self.yAccel) - self.xyCalibrationAngle;
    //    CGFloat yzAngle = atan(self.zAccel/self.yAccel) - self.yzCalibrationAngle;
    CGFloat angle = xyAngle;
    //    CGFloat angle = atanf(sqrtf(tanf(xyAngle)*tanf(xyAngle)+tanf(yzAngle)*tanf(yzAngle)));
    //    if (self.xAccel > 0) angle = -angle;
    self.angleLabel.text = [NSString stringWithFormat:@"%1.1f", fabsf(angle * DEGREES_PER_RADIAN)];
    if (fabsf(angle - self.angleSlider.value) > TOLERANCE){
        self.angleSlider.value = angle;
        [self.angleView setNeedsDisplay];
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

#pragma mark SLLaunchAngleViewDataSource method

- (CGFloat)angleForLaunchAngleView:(SLLaunchAngleView *)sender{
    return self.angleSlider.value;
}

#pragma mark - User Interface

- (IBAction)angleSliderValueChanged:(UISlider *)sender {
    //self.angleView.angle = sender.value;
    self.angleLabel.text = [NSString stringWithFormat:@"%1.1f",fabsf(sender.value * DEGREES_PER_RADIAN)];
    [self.angleView setNeedsDisplay];
}

- (IBAction)motionButtonPressed:(UIBarButtonItem *)sender {
    if ([sender.title isEqualToString:@"Motion On"]){
        self.angleSlider.enabled = NO;
        [self startMotionUpdates];
        sender.title = @"Motion Off";
        self.calibrateButton.enabled = YES;
    }else{
        self.angleSlider.enabled = YES;
        [self stopMotionUpdates];
        sender.title = @"Motion On";
        self.calibrateButton.enabled = NO;
    }
}

- (IBAction)calibrateButtonPressed:(UIBarButtonItem *)sender {
    self.xyCalibrationAngle = atanf(self.xAccel/self.yAccel);
    self.yzCalibrationAngle = atanf(self.zAccel/self.yAccel);
    NSNumber *xyCalibration = [NSNumber numberWithFloat:self.xyCalibrationAngle];
    NSNumber *yzCalibration = [NSNumber numberWithFloat:self.yzCalibrationAngle];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *settings = [[defaults objectForKey:SETTINGS_KEY] mutableCopy];
    [settings setObject:xyCalibration forKey:XY_CAL_KEY];
    [settings setObject:yzCalibration forKey:YZ_CAL_KEY];
    [defaults setObject:settings forKey:SETTINGS_KEY];
    [defaults synchronize];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"PhotoAngleSegue"]){
        [segue.destinationViewController setDelegate:self.delegate];
        [(SLPhotoAngleViewController *)segue.destinationViewController setXyCalibrationAngle: self.xyCalibrationAngle];
        [(SLPhotoAngleViewController *)segue.destinationViewController setYzCalibrationAngle: self.yzCalibrationAngle];
        [self stopMotionUpdates];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    NSString *backgroundFileName = [[NSBundle mainBundle] pathForResource: BACKGROUND_IMAGE_FILENAME ofType:@"png"];
    UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:backgroundFileName];
    [backgroundView setImage:backgroundImage];
    [self.view insertSubview:backgroundView atIndex:0];
    self.calibrateButton.enabled = NO;
    self.motionButton.title = @"Motion On";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *settings = [defaults objectForKey:SETTINGS_KEY];
    self.xyCalibrationAngle = [[settings objectForKey:XY_CAL_KEY] floatValue];
    self.yzCalibrationAngle = [[settings objectForKey:YZ_CAL_KEY] floatValue];
    float launchAngle = [[settings objectForKey:LAUNCH_ANGLE_KEY] floatValue];
    self.angleLabel.text = [NSString stringWithFormat:@"%1.1f", launchAngle * DEGREES_PER_RADIAN];
    [self.angleSlider setValue: launchAngle animated:YES];
    self.angleView.dataSource = self;
    
    // check to see if the device has a camera.  If not, remove the camera button from the toolbar
    if (![[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerCameraDeviceRear] containsObject:(NSString *)kUTTypeImage]){
        NSMutableArray *buttons = [self.toolbarItems mutableCopy];
        [buttons removeObject:self.cameraButton];
        [self setToolbarItems:buttons animated:YES];
        self.cameraButton = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *settings = [[defaults objectForKey:SETTINGS_KEY] mutableCopy];
    [settings setObject: [NSNumber numberWithFloat:fabsf(self.angleSlider.value)] forKey:LAUNCH_ANGLE_KEY];
    [defaults setObject:settings forKey:SETTINGS_KEY];
    [self.delegate sender:self didChangeLaunchAngle:[NSNumber numberWithFloat:fabsf(self.angleSlider.value)]];
    [defaults synchronize];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *settings = [[defaults objectForKey:SETTINGS_KEY] mutableCopy];
    [self.delegate sender:self didChangeLaunchAngle:[NSNumber numberWithFloat:[self.angleLabel.text floatValue]]];
    [settings setObject: [NSNumber numberWithFloat:fabsf(self.angleSlider.value)] forKey:LAUNCH_ANGLE_KEY];
    [defaults setObject:settings forKey:SETTINGS_KEY];
    [defaults synchronize];
    self.accelerometer.delegate = nil;
    self.accelerometer = nil;
    [self setAngleLabel:nil];
    [self setAngleSlider:nil];
    [self setMotionButton:nil];
    [self setCalibrateButton:nil];
    [self setCameraButton:nil];
    [super viewDidUnload];

}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // We have to keep upright for the accelerometer to work
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
