//
//  Launch Angle visual representation
//  Smart Launch
//
//  Created by J. Howard Smart on 2/19/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLLaunchAngleViewController.h"
#import "SLLaunchAngleView.h"
#import "CoreMotion/CoreMotion.h"
#import "SLPhotoAngleViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "SLAppDelegate.h"

#define TOLERANCE 0.001

@interface SLLaunchAngleViewController() <SLLaunchAngleViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *angleLabel;
@property (nonatomic, weak) IBOutlet SLLaunchAngleView *angleView;
@property (weak, nonatomic) IBOutlet UISlider *angleSlider;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *motionQueue;
@property (nonatomic) CMAccelerometerData *accelerometerData;
@property (nonatomic) double xAccel;
@property (nonatomic) double yAccel;
@property (nonatomic) double zAccel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *motionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *calibrateButton;
@property (nonatomic) CGFloat xyCalibrationAngle;
@property (nonatomic) CGFloat yxCalibrationAngle;   // for iPad landscape users
@property (nonatomic) CGFloat yzCalibrationAngle;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;

@end

@implementation SLLaunchAngleViewController

- (CMMotionManager *)motionManager{
    if (!_motionManager){
        _motionManager = [(SLAppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    }
    return _motionManager;
}


#pragma mark - Constant declarations

#define XY_CAL_KEY @"com.smartsoftware.launchsafe.xyCalibrationValue"
#define YX_CAL_KEY @"com.smartsoftware.launchsafe.yxCalibrationValue"
#define YZ_CAL_KEY @"com.smartsoftware.launchsafe.yzCalibrationValue"


//Filtering constants
#define UPDATE_INTERVAL 0.05
#define FILTER_CONSTANT 0.1 //smaller number gives smoother, slower response

- (void)setAccelerometerData:(CMAccelerometerData *)accelerometerData{
    CMAcceleration accel = accelerometerData.acceleration;
    
    //Low-pass filter for accelerometer measurements
    CGFloat alpha  = FILTER_CONSTANT;
    self.xAccel = accel.x * alpha + self.xAccel * (1.0 - alpha);
    self.yAccel = accel.y * alpha + self.yAccel * (1.0 - alpha);
    self.zAccel = accel.z * alpha + self.zAccel * (1.0 - alpha);
    
    //Now that they are filtered we can use the results to display the launch angle
    //The disabled lines add the third dimension and result in some unhappy display problems.  Hmm...
    
    CGFloat xyAngle;
    if (self.splitViewController){   //iPad
        xyAngle = atan(self.yAccel/self.xAccel) - self.yxCalibrationAngle;
        if (self.xAccel > 0) xyAngle = -xyAngle;
    }else{    // iPhone
        xyAngle = atan(self.xAccel/self.yAccel) - self.xyCalibrationAngle;
    }
    //    CGFloat yzAngle = atan(self.zAccel/self.yAccel) - self.yzCalibrationAngle;
    CGFloat angle = xyAngle;
    //    CGFloat angle = atanf(sqrtf(tanf(xyAngle)*tanf(xyAngle)+tanf(yzAngle)*tanf(yzAngle)));
    
    self.angleLabel.text = [NSString stringWithFormat:@"%1.1f", fabsf(angle * DEGREES_PER_RADIAN)];
    if (fabsf(angle - self.angleSlider.value) > TOLERANCE){
        self.angleSlider.value = angle;
        [self.angleView setNeedsDisplay];
    }
}

- (NSOperationQueue *)motionQueue{
    if (!_motionQueue){
        _motionQueue = [[NSOperationQueue alloc] init];
    }
    return _motionQueue;
}

- (void)startMotionUpdates{
    __weak SLLaunchAngleViewController *myWeakSelf = self;
    [self.motionManager setDeviceMotionUpdateInterval:UPDATE_INTERVAL];
    [self.motionManager startAccelerometerUpdatesToQueue:self.motionQueue withHandler:^(CMAccelerometerData *data, NSError *err){
        if (!err){
            myWeakSelf.accelerometerData = data;
        }
        else{
            [myWeakSelf stopMotionUpdates];
            [myWeakSelf.motionButton setTitle:NSLocalizedString(@"Motion On", @"Motion On")];
            myWeakSelf.calibrateButton.enabled = NO;
        }
    }];
}

- (void)stopMotionUpdates{
    [self.motionManager stopAccelerometerUpdates];
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
    if ([sender.title isEqualToString:NSLocalizedString(@"Motion On", @"Motion On")]){
        self.angleSlider.enabled = NO;
        [self startMotionUpdates];
        sender.title = NSLocalizedString(@"Motion Off", @"Motion Off");
        self.calibrateButton.enabled = YES;
    }else{
        self.angleSlider.enabled = YES;
        [self stopMotionUpdates];
        sender.title = NSLocalizedString(@"Motion On", @"Motion On");
        self.calibrateButton.enabled = NO;
    }
}

- (IBAction)calibrateButtonPressed:(UIBarButtonItem *)sender {
    self.xyCalibrationAngle = atanf(self.xAccel/self.yAccel);
    self.yxCalibrationAngle = atanf(self.yAccel/self.xAccel);
    self.yzCalibrationAngle = atanf(self.zAccel/self.yAccel);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *settings = [[defaults objectForKey:SETTINGS_KEY] mutableCopy];
    settings[XY_CAL_KEY] = @(self.xyCalibrationAngle);
    settings[YX_CAL_KEY] = @(self.yxCalibrationAngle);
    settings[YZ_CAL_KEY] = @(self.yzCalibrationAngle);
    [defaults setObject:settings forKey:SETTINGS_KEY];
    [defaults synchronize];
    
}

- (IBAction)cameraButtonPressed:(UIBarButtonItem*)sender{
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"PhotoAngleSegue"]){
        [segue.destinationViewController setDelegate:self.delegate];
        [(SLPhotoAngleViewController *)segue.destinationViewController setXyCalibrationAngle: self.xyCalibrationAngle];
        [(SLPhotoAngleViewController *)segue.destinationViewController setYxCalibrationAngle: self.yxCalibrationAngle];
        [(SLPhotoAngleViewController *)segue.destinationViewController setYzCalibrationAngle: self.yzCalibrationAngle];
        [self stopMotionUpdates];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.splitViewController){
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        [self.view insertSubview:backgroundView atIndex:0];
    }else{
        self.view.backgroundColor = [SLCustomUI iPadBackgroundColor];
    }
    self.calibrateButton.enabled = NO;
    self.motionButton.title = NSLocalizedString(@"Motion On", @"Motion On");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *settings = [defaults objectForKey:SETTINGS_KEY];
    self.xyCalibrationAngle = [settings[XY_CAL_KEY] floatValue];
    self.yxCalibrationAngle = [settings[YX_CAL_KEY] floatValue];
    self.yzCalibrationAngle = [settings[YZ_CAL_KEY] floatValue];
    float launchAngle = [settings[LAUNCH_ANGLE_KEY] floatValue];
    self.angleLabel.text = [NSString stringWithFormat:@"%1.1f", launchAngle * DEGREES_PER_RADIAN];
    [self.angleSlider setValue: launchAngle animated:YES];
    self.angleView.dataSource = self;
    
    // check to see if the device has a camera.  If not, or if it is an iPad remove the camera button from the toolbar
    // maybe some day I will figure out how to present the camera in the master view controller's space
    if (![[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeImage] || self.splitViewController){
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
    [self.delegate sender:self didChangeLaunchAngle:@(fabsf(self.angleSlider.value))];
    [self.motionManager stopAccelerometerUpdates];
    [super viewWillDisappear:animated];
}

-(NSString *)description{
    return @"LaunchAngleViewController";
}

-(void)dealloc{
    [self.motionManager stopAccelerometerUpdates];
}

@end
