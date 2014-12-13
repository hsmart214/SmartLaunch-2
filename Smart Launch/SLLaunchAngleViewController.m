//
//  Launch Angle visual representation
//  Smart Launch
//
//  Created by J. Howard Smart on 2/19/12.
//  Copyright (c) 2012 All rights reserved.
//

@import MobileCoreServices;
@import CoreMotion;
#import "SLLaunchAngleViewController.h"
#import "SLLaunchAngleView.h"
#import "SLAppDelegate.h"

#define TOLERANCE 0.001
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


@interface SLLaunchAngleViewController() <SLLaunchAngleViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

{
    UIImagePickerController *cameraUI;
}

@property (weak, nonatomic) IBOutlet UILabel *angleLabel;
@property (nonatomic, weak) IBOutlet SLLaunchAngleView *angleView;
@property (nonatomic, strong) UIView *photoAngleView;
@property (nonatomic, strong) UILabel *photoAngleLabel;
@property (weak, nonatomic) IBOutlet UISlider *angleSlider;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *motionQueue;
@property (nonatomic) double xAccel;
@property (nonatomic) double yAccel;
@property (nonatomic) double zAccel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *motionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *calibrateButton;
@property (nonatomic) CGFloat xyCalibrationAngle;
@property (nonatomic) CGFloat yxCalibrationAngle;   // for iPad landscape users
@property (nonatomic) CGFloat yzCalibrationAngle;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (nonatomic, strong) UIImageView *warningView;
@property (nonatomic, strong) UIButton *acceptButton;
@property (nonatomic, strong) UIButton *cancelButton;


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
#define UPDATE_INTERVAL 0.2
#define FILTER_CONSTANT 0.02 //smaller number gives smoother, slower response

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
        xyAngle = self.yAccel != 0.0 ? atan(self.xAccel/self.yAccel) - self.xyCalibrationAngle : 0.0;
    }
    //    CGFloat yzAngle = atan(self.zAccel/self.yAccel) - self.yzCalibrationAngle;
    CGFloat angle = xyAngle;
    //    CGFloat angle = atanf(sqrtf(tanf(xyAngle)*tanf(xyAngle)+tanf(yzAngle)*tanf(yzAngle)));
    
    NSString *angleString = [NSString stringWithFormat:@"%1.1f", fabs(angle * DEGREES_PER_RADIAN)];
    __weak SLLaunchAngleViewController *wSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        wSelf.angleLabel.text = angleString;
    });
    
    if (fabs(angle - self.angleSlider.value) > TOLERANCE){
        if (!cameraUI) self.currentAngle = angle;
        dispatch_async(dispatch_get_main_queue(), ^{
            wSelf.angleSlider.value = angle;
            [wSelf.angleView setNeedsDisplay];
        });
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        wSelf.photoAngleLabel.text = [NSString stringWithFormat:@"%1.1f°", fabsf(angle) * DEGREES_PER_RADIAN];
    });
    
    if (fabsf(angle) > MAX_LAUNCH_GUIDE_ANGLE){
        dispatch_async(dispatch_get_main_queue(), ^{
            [wSelf.warningView setHidden:NO];
            [wSelf.acceptButton setHidden:YES];
        });
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [wSelf.warningView setHidden:YES];
            [wSelf.acceptButton setHidden:NO];
        });
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
            [myWeakSelf setAccelerometerData: data];
        }
        else{
            //NSLog(@"%@",[err debugDescription]);
            [myWeakSelf stopMotionUpdates];
            [myWeakSelf.motionButton setTitle:NSLocalizedString(@"Motion On", @"Motion On")];
            myWeakSelf.calibrateButton.enabled = NO;
        }
    }];
}

- (void)stopMotionUpdates{
    [self.motionManager stopAccelerometerUpdates];
    self.motionQueue = nil;
    self.calibrateButton.enabled = NO;
    self.motionButton.title = NSLocalizedString(@"Motion On", @"Motion On");
}

#pragma mark SLLaunchAngleViewDataSource method

- (CGFloat)angleForLaunchAngleView:(SLLaunchAngleView *)sender{
    return self.angleSlider.value;
}

#pragma mark - UIImagePickerController delegate

- (BOOL)startCameraControllerFromViewController: (UIViewController*) controller
                                  usingDelegate: (id <UIImagePickerControllerDelegate,
                                                  UINavigationControllerDelegate>) delegate {
    
    if ((![UIImagePickerController isSourceTypeAvailable:
           UIImagePickerControllerSourceTypeCamera])
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    
    cameraUI = [[UIImagePickerController alloc] init];
    if (!cameraUI) return NO;
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    cameraUI.allowsEditing = NO;
    
    cameraUI.delegate = delegate;
    cameraUI.showsCameraControls = NO;
    cameraUI.cameraOverlayView = self.photoAngleView;
    [controller presentViewController:cameraUI animated:YES completion:^{
        self.photoAngleView.opaque = NO;
        [self startMotionUpdates];
    }];
    
    
    return YES;
}

- (UIView *)photoAngleView{
    if (!_photoAngleView){
        _photoAngleView = [[UIView alloc] initWithFrame:self.view.bounds];
        
        UIImageView *viewFinderView = [[UIImageView alloc] initWithFrame:self.view.window.bounds];
        UIImage *viewFinderImage = [UIImage imageNamed:VIEW_FINDER_IMAGE_FILENAME];
        
        [viewFinderView setImage:viewFinderImage];
        [_photoAngleView addSubview:self.warningView];
        [self.warningView setHidden:YES];
        [_photoAngleView addSubview:viewFinderView];
        
        self.photoAngleLabel = [[UILabel alloc] initWithFrame:CGRectMake(108, 20, 105, 58)];
        UIFont *newFont =[self.angleLabel.font fontWithSize:ANGLE_VIEW_FONT_SIZE];
        
        [self.photoAngleLabel setFont:newFont];
        [self.photoAngleLabel setNumberOfLines:1];
        [self.photoAngleLabel setTextColor:[UIColor whiteColor]];
        [self.photoAngleLabel setTextAlignment:NSTextAlignmentCenter];
        self.photoAngleLabel.text = @"0.0°";
        [self.photoAngleLabel setBackgroundColor:[UIColor clearColor]];
        [_photoAngleView addSubview: self.photoAngleLabel];
        
        //make the accept button image
        
        UIImage *acceptButtonImage = [UIImage imageNamed:ACCEPT_BUTTON_FILENAME];
        UIImage *acceptSelectedImage = [UIImage imageNamed:ACCEPT_SELECTED_FILENAME];
        
        CGRect buttonFrame = CGRectMake(self.view.bounds.size.width/2 + BUTTON_HEIGHT/4, self.view.bounds.size.height - BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT);
        self.acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.acceptButton setFrame:buttonFrame];
        [self.acceptButton setTitle:NSLocalizedString(@"Accept", @"Accept")
                           forState:UIControlStateNormal];
        [self.acceptButton addTarget:self action:@selector(acceptAngle) forControlEvents:UIControlEventTouchUpInside];
        [self.acceptButton setHidden:NO];
        [self.acceptButton setUserInteractionEnabled:YES];
        [self.acceptButton setImage:acceptButtonImage forState:UIControlStateNormal];
        [self.acceptButton setImage:acceptSelectedImage forState:UIControlStateHighlighted];
        [_photoAngleView addSubview:self.acceptButton];
        
        //make the cancel button image
        
        UIImage *cancelButtonImage = [UIImage imageNamed:CANCEL_BUTTON_FILENAME];
        UIImage *cancelSelectedImage = [UIImage imageNamed:CANCEL_SELECTED_FILENAME];
        
        buttonFrame = CGRectMake(self.view.bounds.size.width/2 - BUTTON_WIDTH - BUTTON_HEIGHT/4, self.view.bounds.size.height - BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT);
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cancelButton setFrame:buttonFrame];
        [self.cancelButton setTitle:NSLocalizedString(@"Cancel", @"Cancel")
                           forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelButton setHidden:NO];
        [self.cancelButton setUserInteractionEnabled:YES];
        [self.cancelButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self.cancelButton setImage:cancelButtonImage forState:UIControlStateNormal];
        [self.cancelButton setImage:cancelSelectedImage forState:UIControlStateHighlighted];
        
        [_photoAngleView addSubview:self.cancelButton];
        
    }
    return _photoAngleView;
}

- (UIImageView *)warningView{
    if (!_warningView){
        CGFloat x, y;
        x = self.view.bounds.size.width/2 - ANGLE_WARNING_SIZE/2;
        y = self.view.bounds.size.height/2 - ANGLE_WARNING_SIZE/2 + 5;
        _warningView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, ANGLE_WARNING_SIZE, ANGLE_WARNING_SIZE)];
        UIImage *warningImage = [UIImage imageNamed:ANGLE_WARNING_IMAGE_FILENAME];
        [_warningView setImage:warningImage];
    }
    return _warningView;
}

#pragma mark - SLPhotoAngleViewDelegate methods

- (void)acceptAngle{
    float radians = [self.photoAngleLabel.text floatValue]/ DEGREES_PER_RADIAN;
    if (radians > MAX_LAUNCH_GUIDE_ANGLE){
        radians = MAX_LAUNCH_GUIDE_ANGLE;
    }
    NSNumber *angle = @(radians);
    [self.delegate sender:self didChangeLaunchAngle:angle];
    [self stopMotionUpdates];
    self.currentAngle = radians;
    self.angleSlider.value = radians;
    [cameraUI dismissViewControllerAnimated:YES completion:nil];
    cameraUI = nil;
    //[self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)cancel{
    [self.motionManager stopAccelerometerUpdates];
    [self dismissViewControllerAnimated:YES completion:nil];
    cameraUI = nil;
    self.angleSlider.value = self.currentAngle;
    self.angleLabel.text = [NSString stringWithFormat:@"%1.1f",fabsf(self.currentAngle * DEGREES_PER_RADIAN)];
    [self.angleView setNeedsDisplay];
    //[self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - User Interface

- (IBAction)cameraButtonPressed:(UIBarButtonItem *)sender {
    [self startCameraControllerFromViewController:self usingDelegate:self];
}


- (IBAction)angleSliderValueChanged:(UISlider *)sender {
    self.currentAngle = sender.value;
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
        //self.view.backgroundColor = [SLCustomUI iPadBackgroundColor];
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_FOR_IPAD_MASTER_VC];
        [backgroundView setImage:backgroundImage];
        [self.view insertSubview:backgroundView atIndex:0];
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
    self.currentAngle = launchAngle;
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
    [self stopMotionUpdates];
    [self.delegate sender:self didChangeLaunchAngle:@(fabsf(self.angleSlider.value))];
    [super viewWillDisappear:animated];
}

-(NSString *)description{
    return @"LaunchAngleViewController";
}

-(void)dealloc{
    [self.motionManager stopAccelerometerUpdates];
    _motionManager = nil;
    _motionQueue = nil;
    _photoAngleLabel = nil;
    _photoAngleView = nil;
    _acceptButton = nil;
    _cancelButton = nil;
    _warningView = nil;
}

@end
