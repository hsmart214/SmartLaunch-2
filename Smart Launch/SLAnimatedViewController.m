//
//  SLAnimatedViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/25/12.
//  Copyright (c) 2012 All rights reserved.
//

@import QuartzCore;
#import "SLAnimatedViewController.h"
#import "SLUnitsConvertor.h"
#import "SLAnimatedRocketView.h"

#define ROCKET_PIC_HEIGHT 300

@interface SLAnimatedViewController ()

@property (weak, nonatomic) IBOutlet SLAnimatedRocketView *rocketView;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffVelocityUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityLabel;
@property (weak, nonatomic) IBOutlet UIStepper *windVelocityStepper;
@property (weak, nonatomic) IBOutlet UILabel *ffVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffAoALabel;
@property (weak, nonatomic) IBOutlet UILabel *launchGuideLengthUnitsLabel;
@property (weak, nonatomic) IBOutlet UIStepper *launchGuideLengthStepper;
@property (weak, nonatomic) IBOutlet UILabel *launchGuideLengthLabel;
@property (weak, nonatomic) IBOutlet UIButton *launchDirectionButton;
//These properties are kept locally for the display of vectors - sort of "what it" scenarios - Always kept as metric values so the calculation will be fast
@property (nonatomic) float displayLaunchAngle;
@property (nonatomic) float displayFFVelocity;
@property (nonatomic) float displayWindVelocity;
@property (nonatomic) float displayLaunchGuideLength;
@property (nonatomic) LaunchDirection displayLaunchDirection;
@property (nonatomic, strong) NSString *launchGuideLengthFormatString;


@end

@implementation SLAnimatedViewController


- (void)setDisplayLaunchAngle:(float)angle{
    if (angle == _displayLaunchAngle) return;
    if (angle < 0) angle = 0;
    if (angle > MAX_LAUNCH_GUIDE_ANGLE) angle = MAX_LAUNCH_GUIDE_ANGLE;
    _displayLaunchAngle = angle;
    self.displayFFVelocity = [self.dataSource quickFFVelocityAtAngle:_displayLaunchAngle andGuideLength:_displayLaunchGuideLength];
}
- (IBAction)windVelocityChanged:(UIStepper *)sender {
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%2.0f", sender.value];
    self.displayWindVelocity = [SLUnitsConvertor metricStandardOf:sender.value forKey:VELOCITY_UNIT_KEY];
    [self updateDisplay];
}

- (IBAction)launchGuideLengthValueChanged:(UIStepper *)sender { // Remember this stepper keeps values in display units, not metric
    self.displayLaunchGuideLength = [SLUnitsConvertor metricStandardOf:(float)sender.value forKey:LENGTH_UNIT_KEY];
    self.launchGuideLengthLabel.text = [NSString stringWithFormat:self.launchGuideLengthFormatString, sender.value];
    self.displayFFVelocity = [self.dataSource quickFFVelocityAtAngle:_displayLaunchAngle andGuideLength:_displayLaunchGuideLength];
    [self updateDisplay];
}

- (IBAction)handleRocketTiltPanGesture:(UIPanGestureRecognizer *)gesture {
    if (self.displayLaunchDirection == CrossWind) return;       // The launch angle always appears vertical for crosswind calculations
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

- (IBAction)pullValuesFromSimulation:(UIBarButtonItem *)sender {
    [self importSimValues];
}

- (IBAction)pushValuesToSimulation:(UIBarButtonItem *)sender{
    NSMutableDictionary *settings = [[self.dataSource simulationSettings] mutableCopy];
    settings[LAUNCH_ANGLE_KEY] = @(self.displayLaunchAngle);
    settings[LAUNCH_GUIDE_LENGTH_KEY] = @(self.displayLaunchGuideLength);
    settings[WIND_VELOCITY_KEY] = @(self.displayWindVelocity);
    [self.delegate sender:self didChangeSimSettings:settings withUpdate:NO];
}

- (IBAction)launchDirectionChanged:(UIButton *)sender {
    NSArray *buttonNames = @[NSLocalizedString(@"With Wind", @"With Wind") ,
                             NSLocalizedString(@"CrossWind", @"CrossWind"),
                             NSLocalizedString(@"Into Wind", @"Into Wind")];
    NSInteger dir;
    for (dir = 0; dir < 3; dir++) {
        if ([sender.currentTitle isEqualToString:buttonNames[dir]]){
            break;
        }
    }
    dir = (dir + 1) % 3;
    [sender setTitle:buttonNames[dir] forState:UIControlStateNormal];
    self.displayLaunchDirection = (LaunchDirection)dir;
    [sender setTitle: buttonNames[dir] forState:UIControlStateNormal];
    [self updateDisplay];

}


- (void)drawVectors{
    float wind = [SLUnitsConvertor metricStandardOf:self.displayWindVelocity forKey:VELOCITY_UNIT_KEY];
    float velocity = self.displayFFVelocity;
    float launchAngle = self.displayLaunchAngle;
    LaunchDirection dir = self.displayLaunchDirection;
    if (dir == CrossWind) launchAngle = 0.0;           // crosswind the AoA is the same as upright
    
    [self.rocketView tiltRocketToAngle:launchAngle];   // in the model the launch angle is always positive
    
    if (dir == IntoWind) wind = -wind;                 // this is how we display the opposite wind direction
    
    [self.rocketView UpdateVectorsWithRocketVelocity:velocity andWindVelocity:wind];
}

- (void)updateDisplay{
    
    self.ffVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    float velocity = [SLUnitsConvertor displayUnitsOf:self.displayFFVelocity forKey:VELOCITY_UNIT_KEY];
    self.ffVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", velocity];
    
    float AoA, alpha1, alpha2, opposite, adjacent;
    switch (self.displayLaunchDirection) {
        case CrossWind:
            AoA = atanf([SLUnitsConvertor metricStandardOf:self.windVelocityStepper.value forKey:VELOCITY_UNIT_KEY] /self.displayFFVelocity);
            break;
            
        case WithWind:
            alpha1 = self.displayLaunchAngle;
            opposite = self.displayFFVelocity*sin(alpha1)-[SLUnitsConvertor metricStandardOf:self.windVelocityStepper.value forKey:VELOCITY_UNIT_KEY];
            adjacent = self.displayFFVelocity*cos(alpha1);
            alpha2 = atanf(opposite/adjacent);
            AoA = alpha1-alpha2;
            break;
        case IntoWind:
            alpha1 = self.displayLaunchAngle;
            opposite = self.displayFFVelocity*sin(alpha1)+[SLUnitsConvertor metricStandardOf:self.windVelocityStepper.value forKey:VELOCITY_UNIT_KEY];
            adjacent = self.displayFFVelocity*cos(alpha1);
            alpha2 = atanf(opposite/adjacent);
            AoA = alpha2-alpha1;
            break;
        default:
            break;
    }
    if (self.windVelocityStepper.value == 0) AoA = 0.0;
    AoA *= DEGREES_PER_RADIAN;
    self.ffAoALabel.text = [NSString stringWithFormat:@"%2.1f",AoA];
    [self drawVectors];
}

- (void)importSimValues{
    float velocity = [SLUnitsConvertor displayUnitsOf:[self.dataSource windVelocity] forKey:VELOCITY_UNIT_KEY];
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%1.0f", velocity];
    self.windVelocityStepper.value = [SLUnitsConvertor displayUnitsOf:[self.dataSource windVelocity] forKey:VELOCITY_UNIT_KEY];
    self.ffAoALabel.text = [NSString stringWithFormat:@"%1.1f", [self.dataSource freeFlightAoA] * DEGREES_PER_RADIAN];
    self.displayWindVelocity = [SLUnitsConvertor metricStandardOf:self.windVelocityStepper.value forKey:VELOCITY_UNIT_KEY];
    self.displayLaunchAngle = [self.dataSource launchAngle];
    self.displayFFVelocity = [self.dataSource freeFlightVelocity];
    self.displayLaunchGuideLength = [self.dataSource launchGuideLength];
    float displayLength = [SLUnitsConvertor displayUnitsOf:[self.dataSource launchGuideLength] forKey:LENGTH_UNIT_KEY];
    self.launchGuideLengthLabel.text = [NSString stringWithFormat:@"%2.0f", displayLength];
    self.launchGuideLengthStepper.value = [SLUnitsConvertor displayUnitsOf:[self.dataSource launchGuideLength] forKey:LENGTH_UNIT_KEY];
    self.displayLaunchDirection = [self.dataSource launchGuideDirection];
    NSArray *buttonNames = @[NSLocalizedString(@"With Wind", @"With Wind") ,
                             NSLocalizedString(@"CrossWind", @"CrossWind"),
                             NSLocalizedString(@"Into Wind", @"Into Wind")];
    [self.launchDirectionButton setTitle:buttonNames[self.displayLaunchDirection] forState:UIControlStateNormal];
    [self updateDisplay];
}

- (void)setUpUnits{
    self.windVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    self.launchGuideLengthUnitsLabel.text = [SLUnitsConvertor displayStringForKey:LENGTH_UNIT_KEY];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *unitPrefs = [defaults objectForKey:UNIT_PREFS_KEY];

    // For this stepper I am keeping the value in display units to avoid awkward rounding errors
    if ([unitPrefs[LENGTH_UNIT_KEY] isEqualToString:K_FEET]){
        self.launchGuideLengthFormatString = @"%1.1f";
        [self.launchGuideLengthStepper setMaximumValue:12];
        self.launchGuideLengthStepper.stepValue = 0.5;
        self.launchGuideLengthStepper.minimumValue = 0.5;
    }else if ([unitPrefs[LENGTH_UNIT_KEY] isEqualToString:K_INCHES]){
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
    if ([unitPrefs[VELOCITY_UNIT_KEY] isEqualToString:K_MILES_PER_HOUR]){
        self.windVelocityStepper.maximumValue = 20;
        self.windVelocityStepper.stepValue = 1.0;
    }else{
        self.windVelocityStepper.maximumValue = 9;
        self.windVelocityStepper.stepValue = 0.5;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self setUpUnits];
    [self importSimValues];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    UIImage *backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
    [backgroundView setImage:backgroundImage];
    [self.view insertSubview:backgroundView atIndex:0];
    
    UIInterpolatingMotionEffect *horiz = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"frame.origin.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    [horiz setMinimumRelativeValue:@(-MOTION_OFFSET)];
    [horiz setMaximumRelativeValue:@(MOTION_OFFSET)];
    UIInterpolatingMotionEffect *vert = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"frame.origin.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    [vert setMinimumRelativeValue:@(-MOTION_OFFSET)];
    [vert setMaximumRelativeValue:@(MOTION_OFFSET)];
    UIMotionEffectGroup *motions = [[UIMotionEffectGroup alloc] init];
    [motions setMotionEffects:@[horiz, vert]];
    
    [self.rocketView addMotionEffect:motions];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.rocketView.avatar = [self.dataSource avatarName];
    [self.rocketView startFresh];
    [self updateDisplay];
}

-(void)dealloc{
    self.launchGuideLengthFormatString = nil;
}

-(NSString *)description{
    return @"AnimatedViewController";
}

@end
