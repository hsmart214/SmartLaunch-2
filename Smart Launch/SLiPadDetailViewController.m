//
//  SLiPadDetailViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 3/9/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLiPadDetailViewController.h"
#import "SLCurveGraphView.h"
#import "SLUnitsConvertor.h"
#import "SLAnimatedRocketView.h"

@interface SLiPadDetailViewController ()<SLCurveGraphViewDelegate, SLCurveGraphViewDataSource>

@property (weak, nonatomic) IBOutlet SLCurveGraphView *thrustCurveView;
@property (weak, nonatomic) IBOutlet SLCurveGraphView *flightProfileView;
@property (weak, nonatomic) IBOutlet UILabel *flightProfileGraphTitleLabel;
@property (weak, nonatomic) IBOutlet SLAnimatedRocketView *rocketView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *graphTypeSegmentedControl;
@property (weak, nonatomic) IBOutlet UIStepper *launchGuideLengthStepper;
@property (weak, nonatomic) IBOutlet UILabel *launchGuideLengthUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *launchGuideLengthLabel;
@property (weak, nonatomic) IBOutlet UIStepper *windVelocityStepper;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalImpulseLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffAoALabel;
@property (weak, nonatomic) IBOutlet UILabel *ffVelocityUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *launchSiteAltLabel;
@property (weak, nonatomic) IBOutlet UILabel *launchSiteAltUnitsLabel;
@property (weak, nonatomic) IBOutlet UIStepper *siteAltitudeStepper;
@property (nonatomic) float displayLaunchAngle;
@property (nonatomic) enum LaunchDirection displayLaunchDirection;
@property (nonatomic) float displayFFVelocity;
@property (nonatomic) float displayWindVelocity;
@property (nonatomic) float displayLaunchGuideLength;
@property (nonatomic) float displayLaunchAltitude;
@property (nonatomic, strong) NSString *launchGuideLengthFormatString;

@end

@implementation SLiPadDetailViewController

- (IBAction)pullSimData:(UIButton *)sender {
    [self updateDisplay];
}

- (IBAction)pushSimData:(UIButton *)sender {
    NSMutableDictionary *settings = [[self.simDataSource simulationSettings] mutableCopy];
    settings[LAUNCH_ANGLE_KEY] = @(self.displayLaunchAngle);
    settings[LAUNCH_GUIDE_LENGTH_KEY] = @(self.displayLaunchGuideLength);
    settings[WIND_VELOCITY_KEY] = @(self.displayWindVelocity);
    settings[LAUNCH_ALTITUDE_KEY] = @(self.displayLaunchAltitude);
    [self.simDelegate sender:self didChangeSimSettings:settings withUpdate:YES];
}

-(void)updateDisplay{
    [self setUpUnits];
    [self importSimValues];
    [self updateGraphDisplay];
    [self updateAoADisplay];
}

-(void)setModel:(SLPhysicsModel *)model{
    _model = model;
    self.dataSource = _model;
}

- (IBAction)flightProfileGraphTypeChanged:(UISegmentedControl *)sender {
    [self updateGraphDisplay];
}

- (void)setDisplayLaunchAngle:(float)angle{
    if (angle == _displayLaunchAngle) return;
    if (angle < 0) angle = 0;
    if (angle > MAX_LAUNCH_GUIDE_ANGLE) angle = MAX_LAUNCH_GUIDE_ANGLE;
    _displayLaunchAngle = angle;
    self.displayFFVelocity = [self.simDataSource quickFFVelocityAtAngle:_displayLaunchAngle andGuideLength:_displayLaunchGuideLength];
}
- (IBAction)windVelocityChanged:(UIStepper *)sender { // Remember this stepper keeps values in display units, not metric
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%2.0f", sender.value];
    self.displayWindVelocity = [[SLUnitsConvertor metricStandardOf:@(sender.value) forKey:VELOCITY_UNIT_KEY] floatValue];
    [self updateAoADisplay];
}

- (IBAction)launchGuideLengthValueChanged:(UIStepper *)sender { // Remember this stepper keeps values in display units, not metric
    self.displayLaunchGuideLength = [[SLUnitsConvertor metricStandardOf:@((float)sender.value) forKey:LENGTH_UNIT_KEY] floatValue];
    self.launchGuideLengthLabel.text = [NSString stringWithFormat:self.launchGuideLengthFormatString, sender.value];
    self.displayFFVelocity = [self.simDataSource quickFFVelocityAtAngle:_displayLaunchAngle andGuideLength:_displayLaunchGuideLength];
    [self updateAoADisplay];
}

- (IBAction)launchSiteAltitudeChanged:(UIStepper *)sender { // Remember this stepper keeps values in display units, not metric
    self.displayLaunchAltitude = [[SLUnitsConvertor metricStandardOf:@(sender.value) forKey:ALT_UNIT_KEY] floatValue];
    self.launchSiteAltLabel.text = [NSString stringWithFormat:@"%1.0f", sender.value];
    [self updateAoADisplay];
}

- (IBAction)handleRocketTiltPanGesture:(UIPanGestureRecognizer *)gesture {
    if (self.displayLaunchDirection == CrossWind) return;       // The launch angle always appears vertical for crosswind calculations
    if ((gesture.state == UIGestureRecognizerStateChanged) ||
        (gesture.state == UIGestureRecognizerStateEnded)) {
        CGPoint movement = [gesture translationInView:self.rocketView];
        float oldAngle = self.displayLaunchAngle;
        float delta = atanf(movement.x/self.rocketView.frame.size.height);
        self.displayLaunchAngle = oldAngle - delta;
        [gesture setTranslation:CGPointZero inView:self.rocketView];
        [self updateAoADisplay];
    }
}

-(void)updateAoADisplay{
    self.ffVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    NSNumber *vel = @(self.displayFFVelocity);
    NSNumber *velocity = [SLUnitsConvertor displayUnitsOf:vel forKey:VELOCITY_UNIT_KEY];
    self.ffVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", [velocity floatValue]];
    
    float AoA, alpha1, alpha2, opposite, adjacent;
    switch (self.displayLaunchDirection) {
        case CrossWind:
            AoA = atanf([[SLUnitsConvertor metricStandardOf:@(self.windVelocityStepper.value) forKey:VELOCITY_UNIT_KEY] floatValue] /self.displayFFVelocity);
            break;
            
        case WithWind:
            alpha1 = self.displayLaunchAngle;
            opposite = self.displayFFVelocity*sin(alpha1)-[[SLUnitsConvertor metricStandardOf:@(self.windVelocityStepper.value) forKey:VELOCITY_UNIT_KEY] floatValue];
            adjacent = self.displayFFVelocity*cos(alpha1);
            alpha2 = atanf(opposite/adjacent);
            AoA = alpha1-alpha2;
            break;
        case IntoWind:
            alpha1 = self.displayLaunchAngle;
            opposite = self.displayFFVelocity*sin(alpha1)+[[SLUnitsConvertor metricStandardOf:@(self.windVelocityStepper.value) forKey:VELOCITY_UNIT_KEY] floatValue];
            adjacent = self.displayFFVelocity*cos(alpha1);
            alpha2 = atanf(opposite/adjacent);
            AoA = alpha2-alpha1;
            break;
        default:
            break;
    }
    if (self.windVelocityStepper.value == 0) AoA = 0.0;
    AoA *= DEGREES_PER_RADIAN;
    self.ffAoALabel.text = [NSString stringWithFormat:@"%1.1f°",AoA];
    [self drawVectors];
}

-(void)drawVectors{
    float wind = [[SLUnitsConvertor metricStandardOf:@(self.displayWindVelocity) forKey:VELOCITY_UNIT_KEY] floatValue];
    float velocity = self.displayFFVelocity;
    float launchAngle = self.displayLaunchAngle;
    enum LaunchDirection dir = self.displayLaunchDirection;
    if (dir == CrossWind) launchAngle = 0.0;           // crosswind the AoA is the same as upright
    
    [self.rocketView tiltRocketToAngle:launchAngle];   // in the model the launch angle is always positive
    
    if (dir == IntoWind) wind = -wind;                 // this is how we display the opposite wind direction
    
    [self.rocketView UpdateVectorsWithRocketVelocity:velocity andWindVelocity:wind];
}

-(void)updateGraphDisplay{
    self.flightProfileGraphTitleLabel.text = [NSString stringWithFormat:@"Flight Profile - %@", [self.graphTypeSegmentedControl titleForSegmentAtIndex:[self.graphTypeSegmentedControl selectedSegmentIndex]]];
    self.motorNameLabel.text = [self.model.motor.manufacturer stringByAppendingString:[NSString stringWithFormat:@" %@", self.model.motor.name]];
    self.totalImpulseLabel.text = [NSString stringWithFormat:@"Total Impulse: %1.0f Newton-sec", [self.model.motor.totalImpulse floatValue]];
    self.title = self.model.rocketName;
    [self.flightProfileView resetAxes];
    [self.thrustCurveView resetAxes];
    NSArray *unitNames = @[VELOCITY_UNIT_KEY, ACCEL_UNIT_KEY, ALT_UNIT_KEY, MACH_UNIT_KEY, THRUST_UNIT_KEY];
    NSArray *formatStrings = @[@"%1.0f",@"%1.0f",@"%1.0f",@"%1.1f", @"%1.0f"];
    NSUInteger index = [self.graphTypeSegmentedControl selectedSegmentIndex];
    [self.flightProfileView setVerticalUnits:[SLUnitsConvertor displayStringForKey:unitNames[index]]withFormat:formatStrings[index]];
    [self.thrustCurveView setVerticalUnits:[SLUnitsConvertor displayStringForKey:THRUST_UNIT_KEY] withFormat:@"%1.0f"];
    [self.thrustCurveView setNeedsDisplay];
    [self.flightProfileView setNeedsDisplay];
}


#pragma mark - SLCurveGraphViewDataSource methods

-(CGFloat)curveGraphViewDataValueRange:(SLCurveGraphView *)sender{
    if (sender == self.flightProfileView){
        switch ((enum SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex]) {
            case SLFlightProfileGraphTypeVelocity:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource maxVelocity] forKey:VELOCITY_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeAcceleration:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource maxAcceleration] forKey:ACCEL_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeAltitude:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource apogeeAltitude] forKey:ALT_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeMach:
                return [[self.dataSource maxMachNumber] floatValue];
            case SLFlightProfileGraphTypeDrag:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource maxDrag] forKey:THRUST_UNIT_KEY] floatValue];
        }
    }else{ //must be thrust curve
        return [[SLUnitsConvertor displayUnitsOf:self.model.motor.peakThrust forKey:THRUST_UNIT_KEY] floatValue];
    }
}

-(CGFloat)curveGraphViewDataValueMinimumValue:(SLCurveGraphView *)sender{
    if (sender == self.thrustCurveView) return 0.0;
    if ([self.graphTypeSegmentedControl selectedSegmentIndex] == SLFlightProfileGraphTypeAcceleration){
        return [[SLUnitsConvertor displayUnitsOf:[self.dataSource maxDeceleration] forKey:ACCEL_UNIT_KEY] floatValue];
    }else{
        return 0.0;
    }
}

-(CGFloat)curveGraphViewTimeValueRange:(SLCurveGraphView *)sender{
    if (sender == self.flightProfileView){
        return [[self.dataSource totalTime] floatValue];
    }else{
        return [[self.model.motor.times lastObject] floatValue];
    }
}

-(CGFloat)curveGraphView:(SLCurveGraphView *)sender dataValueForTimeIndex:(CGFloat)timeIndex{
    if (sender == self.flightProfileView){
        switch ((enum SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex]) {
            case SLFlightProfileGraphTypeVelocity:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource dataAtTime: @(timeIndex) forKey:VEL_INDEX] forKey:VELOCITY_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeAcceleration:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource dataAtTime: @(timeIndex) forKey:ACCEL_INDEX] forKey:ACCEL_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeAltitude:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource dataAtTime: @(timeIndex) forKey:ALT_INDEX] forKey:ALT_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeMach:
                return [[self.dataSource dataAtTime: @(timeIndex) forKey:MACH_INDEX] floatValue];
            case SLFlightProfileGraphTypeDrag:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource dataAtTime: @(timeIndex) forKey:DRAG_INDEX] forKey:THRUST_UNIT_KEY] floatValue];
        }
    }else{ //must be thrust curve
        return [[SLUnitsConvertor displayUnitsOf:@([self.model.motor thrustAtTime:timeIndex]) forKey:THRUST_UNIT_KEY] floatValue];
    }
}

#pragma mark - SLCurveGraphViewDelegate methods

-(NSUInteger)numberOfVerticalDivisions:(SLCurveGraphView *)sender{
    return 5;
}

-(BOOL)shouldDisplayMachOneLine:(SLCurveGraphView *)sender{
    return ((sender == self.flightProfileView)&&(enum SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex] == SLFlightProfileGraphTypeMach);
}


#pragma mark - View Life Cycle

- (void)importSimValues{
    NSNumber *siteAlt = [SLUnitsConvertor displayUnitsOf:[self.simDataSource launchSiteAltitude] forKey:ALT_UNIT_KEY];
    self.siteAltitudeStepper.value = [siteAlt doubleValue];
    self.launchSiteAltLabel.text = [NSString stringWithFormat:@"%1.0f", [siteAlt floatValue]];
    self.displayLaunchAltitude = [[self.simDataSource launchSiteAltitude] floatValue];
    NSNumber *velocity = [SLUnitsConvertor displayUnitsOf:[self.simDataSource windVelocity] forKey:VELOCITY_UNIT_KEY];
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%1.0f", [velocity floatValue]];
    self.windVelocityStepper.value = [[SLUnitsConvertor displayUnitsOf:[self.simDataSource windVelocity] forKey:VELOCITY_UNIT_KEY] floatValue];
    NSNumber *aoa = [self.simDataSource freeFlightAoA];
    self.ffAoALabel.text = [NSString stringWithFormat:@"%1.1f°", [aoa floatValue] * DEGREES_PER_RADIAN];
    self.displayWindVelocity = [[SLUnitsConvertor metricStandardOf:@(self.windVelocityStepper.value) forKey:VELOCITY_UNIT_KEY] floatValue];
    self.displayLaunchAngle = [[self.simDataSource launchAngle] floatValue];
    self.displayFFVelocity = [[self.simDataSource freeFlightVelocity] floatValue];
    self.displayLaunchGuideLength = [[self.simDataSource launchGuideLength]floatValue];
    NSNumber *displayLength = [SLUnitsConvertor displayUnitsOf:[self.simDataSource launchGuideLength] forKey:LENGTH_UNIT_KEY];
    self.launchGuideLengthLabel.text = [NSString stringWithFormat:@"%2.0f", [displayLength floatValue]];
    self.launchGuideLengthStepper.value = [[SLUnitsConvertor displayUnitsOf:[self.simDataSource launchGuideLength] forKey:LENGTH_UNIT_KEY] floatValue];
    self.displayLaunchDirection = [self.simDataSource launchGuideDirection];
}


- (void)setUpUnits{
    self.windVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    self.launchGuideLengthUnitsLabel.text = [SLUnitsConvertor displayStringForKey:LENGTH_UNIT_KEY];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *unitPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    
    // For all steppers I am keeping the value in display units to avoid awkward rounding errors
    if ([unitPrefs[ALT_UNIT_KEY] isEqualToString:K_METERS]){
        [self.siteAltitudeStepper setMaximumValue:4000];
        self.siteAltitudeStepper.stepValue = 50;
    }else{// must be feet
        [self.siteAltitudeStepper setMaximumValue:10000];
        self.siteAltitudeStepper.stepValue = 100;
    }
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
    }else{//meters per second
        self.windVelocityStepper.maximumValue = 9;
        self.windVelocityStepper.stepValue = 0.5;
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.rocketView startFresh];
    [self importSimValues];
    [self updateAoADisplay];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.thrustCurveView.delegate = self;
    self.thrustCurveView.dataSource = self;
    self.flightProfileView.delegate = self;
    self.flightProfileView.dataSource = self;
    [self setUpUnits];
}

//-(void)viewDidLoad{
//    [super viewDidLoad];
//    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
//    UIImage * backgroundImage = [UIImage imageNamed:@"DaVinci"];
//    [backgroundView setImage:backgroundImage];
//    [self.view insertSubview:backgroundView atIndex:0];
//}

@end
