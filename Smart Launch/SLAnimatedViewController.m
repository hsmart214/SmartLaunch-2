//
//  SLAnimatedViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/25/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SLAnimatedViewController.h"
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
@property (weak, nonatomic) IBOutlet UIButton *launchDirectionButton;
//These properties are kept locally for the display of vectors - sort of "what it" scenarios - Always kept as metric values so the calculation will be fast
@property (nonatomic) float displayLaunchAngle;
@property (nonatomic) float displayFFVelocity;
@property (nonatomic) float displayWindVelocity;
@property (nonatomic) float displayLaunchGuideLength;
@property (nonatomic) enum LaunchDirection displayLaunchDirection;
@property (nonatomic, strong) NSString *launchGuideLengthFormatString;


@end

@implementation SLAnimatedViewController

- (void)setDisplayLaunchAngle:(float)angle{
    if (angle == _displayLaunchAngle) return;
    if (angle > MAX_LAUNCH_GUIDE_ANGLE) angle = MAX_LAUNCH_GUIDE_ANGLE;
    if (angle < 0) angle = 0;
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
    NSMutableDictionary *settings = [self.dataSource simulationSettings];
    settings[LAUNCH_ANGLE_KEY] = @(self.displayLaunchAngle);
    settings[WIND_VELOCITY_KEY] = @(self.displayWindVelocity);
    settings[WIND_DIRECTION_KEY] = @(self.displayLaunchDirection);
    settings[LAUNCH_GUIDE_LENGTH_KEY] = [SLUnitsConvertor metricStandardOf:@(self.launchGuideLengthStepper.value) forKey:LENGTH_UNIT_KEY];
    [self.delegate sender:self didChangeSimSettings:settings withUpdate:NO];
}

- (IBAction)launchDirectionChanged:(UIButton *)sender {
    NSArray *buttonNames = @[@"With Wind", @"CrossWind", @"Into Wind"];
    NSInteger dir;
    for (dir = 0; dir < 3; dir++) {
        if ([sender.currentTitle isEqualToString:[buttonNames objectAtIndex:dir]]){
            break;
        }
    }
    dir = (dir + 1) % 3;
    [sender setTitle:[buttonNames objectAtIndex:dir] forState:UIControlStateNormal];
    self.displayLaunchDirection = (enum LaunchDirection)dir;
    [sender setTitle: buttonNames[dir] forState:UIControlStateNormal];
    [self updateDisplay];

}


- (void)drawVectors{
    float wind = self.displayWindVelocity;
    float velocity = self.displayFFVelocity;
    float launchAngle = self.displayLaunchAngle;
    enum LaunchDirection dir = self.displayLaunchDirection;
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
    switch (self.displayLaunchDirection) {
        case CrossWind:
            AoA = atanf(self.windVelocitySlider.value/self.displayFFVelocity);
            break;
            
        case WithWind:
            alpha1 = self.displayLaunchAngle;
            opposite = self.displayFFVelocity*sin(alpha1)-self.windVelocitySlider.value;
            adjacent = self.displayFFVelocity*cos(alpha1);
            alpha2 = atanf(opposite/adjacent);
            AoA = alpha1-alpha2;
            break;
        case IntoWind:
            alpha1 = self.displayLaunchAngle;
            opposite = self.displayFFVelocity*sin(alpha1)+self.windVelocitySlider.value;
            adjacent = self.displayFFVelocity*cos(alpha1);
            alpha2 = atanf(opposite/adjacent);
            AoA = alpha2-alpha1;
            break;
        default:
            break;
    }
    if (self.windVelocitySlider.value == 0) AoA = 0.0;
    AoA *= DEGREES_PER_RADIAN;
    self.ffAoALabel.text = [NSString stringWithFormat:@"%2.1f",AoA];
    [self drawVectors];
}

- (void)importSimValues{
    self.windVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    NSNumber *velocity = [SLUnitsConvertor displayUnitsOf:[self.dataSource windVelocity] forKey:VELOCITY_UNIT_KEY];
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", [velocity floatValue]];
    self.windVelocitySlider.value = [[self.dataSource windVelocity]floatValue]; //always kept metric
    NSNumber *aoa = [self.dataSource freeFlightAoA];
    self.ffAoALabel.text = [NSString stringWithFormat:@"%1.1f", [aoa floatValue] * DEGREES_PER_RADIAN];
    self.displayWindVelocity = self.windVelocitySlider.value;
    self.displayLaunchAngle = [[self.dataSource launchAngle] floatValue];
    self.displayFFVelocity = [[self.dataSource freeFlightVelocity] floatValue];
    self.launchGuideLengthUnitsLabel.text = [SLUnitsConvertor displayStringForKey:LENGTH_UNIT_KEY];
    self.displayLaunchGuideLength = [[self.dataSource launchGuideLength]floatValue];
    NSNumber *displayLength = [SLUnitsConvertor displayUnitsOf:[self.dataSource launchGuideLength] forKey:LENGTH_UNIT_KEY];
    self.launchGuideLengthLabel.text = [NSString stringWithFormat:@"%2.1f", [displayLength floatValue]];
    self.launchGuideLengthStepper.value = [[SLUnitsConvertor displayUnitsOf:[self.dataSource launchGuideLength] forKey:LENGTH_UNIT_KEY] floatValue];
    self.displayLaunchDirection = [self.dataSource launchGuideDirection];
    NSArray *buttonNames = @[@"With Wind", @"CrossWind", @"Into Wind"];
    [self.launchDirectionButton setTitle:buttonNames[self.displayLaunchDirection] forState:UIControlStateNormal];
    [self updateDisplay];
}

- (void)setUpUnits{
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
    [self.rocketView startFresh];
    [self updateDisplay];
}

- (BOOL)shouldAutorotate{
    //If we are on an iPad, we will be inside a splitviewcontroller
    //return (self.splitViewController != nil);
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
