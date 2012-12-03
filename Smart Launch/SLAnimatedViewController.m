//
//  SLAnimatedViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/25/12.
//  Copyright (c) 2012 J. HOWARD SMART. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SLAnimatedViewController.h"
#import "SLDefinitions.h"       
#import "SLUnitsConvertor.h"
#import "SLAnimatedRocketView.h"

#define ROCKET_PIC_HEIGHT 300

@interface SLAnimatedViewController ()

@property (weak, nonatomic) IBOutlet SLAnimatedRocketView *rocketView;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffVelocityUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffAoALabel;
@property (weak, nonatomic) IBOutlet UISlider *windVelocitySlider;
@property (weak, nonatomic) IBOutlet UILabel *launchGuideLengthUnitsLabel;
@property (weak, nonatomic) IBOutlet UIStepper *launchGuideLengthStepper;
@property (weak, nonatomic) IBOutlet UILabel *launchGuideLengthLabel;
//These properties are kept locally for the display of vectors - sort of "what it" scenarios - Always kept as metric values so the calculation will be fast
@property (nonatomic) float displayLaunchAngle;
@property (nonatomic) float displayFFVelocity;
@property (nonatomic) float displayWindVelocity;
@property (nonatomic) float displayLaunchGuideLength;
@property (nonatomic, strong) NSString *launchGuideLengthFormatString;

@end

@implementation SLAnimatedViewController

- (void)setDisplayLaunchAngle:(float)angle{
    if (angle == _displayLaunchAngle) return;
    if (angle > MAX_LAUNCH_GUIDE_ANGLE) angle = MAX_LAUNCH_GUIDE_ANGLE;
    if (angle < -MAX_LAUNCH_GUIDE_ANGLE) angle = -MAX_LAUNCH_GUIDE_ANGLE;
    _displayLaunchAngle = angle;
    self.displayFFVelocity = [self.dataSource quickFFVelocityAtAngle:_displayLaunchAngle andGuideLength:_displayLaunchGuideLength];
}

- (IBAction)windVelocityChanged:(UISlider *)sender {
    NSNumber *wind = [SLUnitsConvertor displayUnitsOf:[NSNumber numberWithFloat:sender.value] forKey:VELOCITY_UNIT_KEY];
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%2.1f", [wind floatValue]];
    self.displayWindVelocity = sender.value;
    [self updateDisplay];
}
- (IBAction)launchGuideLengthValueChanged:(UIStepper *)sender { // Remember this stepper keeps values in display units, not metric
    self.displayLaunchGuideLength = [[SLUnitsConvertor metricStandardOf:[NSNumber numberWithFloat:sender.value] forKey:LENGTH_UNIT_KEY] floatValue];
    self.launchGuideLengthLabel.text = [NSString stringWithFormat:self.launchGuideLengthFormatString, sender.value];
    self.displayFFVelocity = [self.dataSource quickFFVelocityAtAngle:_displayLaunchAngle andGuideLength:_displayLaunchGuideLength];
    [self updateDisplay];
}

- (IBAction)handleRocketTiltPanGesture:(UIPanGestureRecognizer *)gesture {
    if ((gesture.state == UIGestureRecognizerStateChanged) ||
        (gesture.state == UIGestureRecognizerStateEnded)) {
        CGPoint movement = [gesture translationInView:self.rocketView];
        float oldAngle = self.displayLaunchAngle;
        float delta = atanf(movement.x/ROCKET_PIC_HEIGHT);
        self.displayLaunchAngle = oldAngle - delta;
        [gesture setTranslation:CGPointZero inView:self.rocketView];
        [self updateDisplay];
    }
}


- (void)drawVectors{
    float wind = self.displayWindVelocity;
    float velocity = self.displayFFVelocity;
    float launchAngle = self.displayLaunchAngle;
    enum LaunchDirection dir = [self.dataSource launchGuideDirection];
    if (dir == CrossWind) launchAngle = 0.0;           // crosswind the AoA is the same as upright
    
    [self.rocketView tiltRocketToAngle:launchAngle];   // in the model the launch angle is always positive
    
    if (dir == IntoWind) wind = -wind;                 // this is how we display the opposite wind direction
    
    [self.rocketView UpdateVectorsWithRocketVelocity:velocity andWindVelocity:wind];
}

- (void)updateDisplay{
    
    self.ffVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    NSNumber *vel = [NSNumber numberWithFloat:self.displayFFVelocity];
    NSNumber *velocity = [SLUnitsConvertor displayUnitsOf:vel forKey:VELOCITY_UNIT_KEY];
    self.ffVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", [velocity floatValue]];
    
    float AoA, alpha1, alpha2, opposite, adjacent;
    switch ([self.dataSource launchGuideDirection]) {
        case CrossWind:
            AoA = atanf(self.windVelocitySlider.value/[velocity floatValue]);
            break;
            
        case WithWind:
            alpha1 = self.displayLaunchAngle;
            opposite = [velocity floatValue]*sin(alpha1)-self.windVelocitySlider.value;
            adjacent = [velocity floatValue]*cos(alpha1);
            alpha2 = atanf(opposite/adjacent);
            AoA = alpha1-alpha2;
            break;
        case IntoWind:
            alpha1 = self.displayLaunchAngle;
            opposite = [velocity floatValue]*sin(alpha1)+self.windVelocitySlider.value;
            adjacent = [velocity floatValue]*cos(alpha1);
            alpha2 = atanf(opposite/adjacent);
            AoA = alpha2-alpha1;
            break;
        default:
            break;
    }
    AoA *= DEGREES_PER_RADIAN;
    self.ffAoALabel.text = [NSString stringWithFormat:@"%2.1f",AoA];
    [self drawVectors];
}

- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:NO animated:animated];
    self.windVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    NSNumber *velocity = [SLUnitsConvertor displayUnitsOf:[self.dataSource windVelocity] forKey:VELOCITY_UNIT_KEY];
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", [velocity floatValue]];
    self.windVelocitySlider.value = [[self.dataSource windVelocity]floatValue]; //always kept metric
    NSNumber *aoa = [self.dataSource freeFlightAoA];
    self.ffAoALabel.text = [NSString stringWithFormat:@"%1.1f", [aoa floatValue] * DEGREES_PER_RADIAN];
    self.displayWindVelocity = [[self.dataSource windVelocity] floatValue];
    self.displayLaunchAngle = [[self.dataSource launchAngle] floatValue];
    self.displayFFVelocity = [[self.dataSource freeFlightVelocity] floatValue];
    self.launchGuideLengthUnitsLabel.text = [SLUnitsConvertor displayStringForKey:LENGTH_UNIT_KEY];
    self.displayLaunchGuideLength = [[self.dataSource launchGuideLength]floatValue];
    NSNumber *displayLength = [SLUnitsConvertor displayUnitsOf:[self.dataSource launchGuideLength] forKey:LENGTH_UNIT_KEY];
    self.launchGuideLengthLabel.text = [NSString stringWithFormat:@"%2.1f", [displayLength floatValue]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *unitPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    
    // For this stepper I am keeping the value in display units to avoid awkward rounding errors
    if ([[unitPrefs objectForKey:LENGTH_UNIT_KEY] isEqualToString:K_FEET]){
        self.launchGuideLengthFormatString = @"%1.1f";
        [self.launchGuideLengthStepper setMaximumValue:12];
        self.launchGuideLengthStepper.stepValue = 0.5;
        self.launchGuideLengthStepper.minimumValue = 0.5;
    }else if ([[unitPrefs objectForKey:LENGTH_UNIT_KEY] isEqualToString:K_INCHES]){
        self.launchGuideLengthFormatString = @"%1.0f";
        [self.launchGuideLengthStepper setMaximumValue:240];
        self.launchGuideLengthStepper.stepValue = 2.0;
        self.launchGuideLengthStepper.minimumValue = 4.0;
    }else{//must be meters
        self.launchGuideLengthFormatString = @"%1.1f";
        [self.launchGuideLengthStepper setMaximumValue:5];
        self.launchGuideLengthStepper.stepValue = 0.2;
        self.launchGuideLengthStepper.minimumValue = 0.2;
    }
    self.launchGuideLengthStepper.value = [[SLUnitsConvertor displayUnitsOf:[self.dataSource launchGuideLength] forKey:LENGTH_UNIT_KEY] floatValue];
    
    [self updateDisplay];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    NSString *backgroundFileName = [[NSBundle mainBundle] pathForResource: BACKGROUND_IMAGE_FILENAME ofType:@"png"];
    UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:backgroundFileName];
    [backgroundView setImage:backgroundImage];
    [self.view insertSubview:backgroundView atIndex:0];
    [self.rocketView startFresh];
    [self updateDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setRocketView:nil];
    [self setWindVelocityUnitsLabel:nil];
    [self setFfVelocityUnitsLabel:nil];
    [self setWindVelocityLabel:nil];
    [self setFfVelocityLabel:nil];
    [self setFfAoALabel:nil];
    [self setRocketView:nil];
    [self setWindVelocitySlider:nil];
    [self setLaunchGuideLengthUnitsLabel:nil];
    [self setLaunchGuideLengthLabel:nil];
    [self setLaunchGuideLengthStepper:nil];
    [super viewDidUnload];
}
@end
