//
//  SLFlightProfileViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 2/3/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLFlightProfileViewController.h"
#import "SLUnitsConvertor.h"
#import "SLFlightDataPoint.h"

@interface SLFlightProfileViewController ()
@property (weak, nonatomic) IBOutlet UILabel *rocketNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *apogeeLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *coastTimeLabel;

@property (weak, nonatomic) IBOutlet UISegmentedControl *graphTypeSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *altitudeUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *velocityUnitsLabel;
@property (weak, nonatomic) IBOutlet SLCurveGraphView *graphView;
@end

@implementation SLFlightProfileViewController

-(void)updateDisplay{
    self.rocketNameLabel.text = [self.dataSource rocketName];
    self.motorNameLabel.text = [self.dataSource motorDescription];
    self.maxVelocityLabel.text = [NSString stringWithFormat:@"%1.0f",[SLUnitsConvertor displayUnitsOf:[self.dataSource maxVelocity] forKey:VELOCITY_UNIT_KEY]];
    self.apogeeLabel.text = [NSString stringWithFormat:@"%1.0f",[SLUnitsConvertor displayUnitsOf:[self.dataSource apogeeAltitude] forKey:ALT_UNIT_KEY]];
    self.coastTimeLabel.text = [NSString stringWithFormat:@"%1.1f",[self.dataSource coastTime]];
    NSArray *unitNames = @[VELOCITY_UNIT_KEY, ACCEL_UNIT_KEY, ALT_UNIT_KEY, MACH_UNIT_KEY, THRUST_UNIT_KEY];
    NSArray *formatStrings = @[@"%1.0f",@"%1.0f",@"%1.0f",@"%1.1f", @"%1.0f"];
    NSUInteger index = [self.graphTypeSegmentedControl selectedSegmentIndex];
    [self.graphView setVerticalUnits:[SLUnitsConvertor displayStringForKey:unitNames[index]]withFormat:formatStrings[index]];
    
    [self.graphView setNeedsDisplay];
}

- (IBAction)graphTypeChanged:(UISegmentedControl *)sender {
    [self.graphView resetAxes];
    [self updateDisplay];
}


#pragma mark - SLCurveGraphViewDataSource methods

-(CGFloat)curveGraphViewDataValueRange:(SLCurveGraphView *)sender{
    switch ((SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex]) {
        case SLFlightProfileGraphTypeVelocity:
            return [SLUnitsConvertor displayUnitsOf:[self.dataSource maxVelocity] forKey:VELOCITY_UNIT_KEY];
        case SLFlightProfileGraphTypeAcceleration:
            return [SLUnitsConvertor displayUnitsOf:[self.dataSource maxAcceleration] forKey:ACCEL_UNIT_KEY];
        case SLFlightProfileGraphTypeAltitude:
            return [SLUnitsConvertor displayUnitsOf:[self.dataSource apogeeAltitude] forKey:ALT_UNIT_KEY];
        case SLFlightProfileGraphTypeMach:
            return [self.dataSource maxMachNumber];
        case SLFlightProfileGraphTypeDrag:
            return [SLUnitsConvertor displayUnitsOf:[self.dataSource maxDrag] forKey:THRUST_UNIT_KEY];
    }
}

-(CGFloat)curveGraphViewDataValueMinimumValue:(SLCurveGraphView *)sender{
    if ([self.graphTypeSegmentedControl selectedSegmentIndex] == SLFlightProfileGraphTypeAcceleration){
        return [SLUnitsConvertor displayUnitsOf:[self.dataSource maxDeceleration] forKey:ACCEL_UNIT_KEY];
    }else{
        return 0.0;
    }
}

-(CGFloat)curveGraphViewTimeValueRange:(SLCurveGraphView *)sender{
    return [self.dataSource totalTime];
}

-(CGFloat)curveGraphView:(SLCurveGraphView *)thrustCurveView dataValueForTimeIndex:(CGFloat)timeIndex{
    SLFlightDataPoint *dataPoint = [self.dataSource dataAtTime:timeIndex];
    switch ((SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex]) {
        case SLFlightProfileGraphTypeVelocity:
            return [SLUnitsConvertor displayUnitsOf:dataPoint->vel forKey:VELOCITY_UNIT_KEY];
        case SLFlightProfileGraphTypeAcceleration:
            return [SLUnitsConvertor displayUnitsOf:dataPoint->accel forKey:ACCEL_UNIT_KEY];
        case SLFlightProfileGraphTypeAltitude:
            return [SLUnitsConvertor displayUnitsOf:dataPoint->alt forKey:ALT_UNIT_KEY];
        case SLFlightProfileGraphTypeMach:
            return dataPoint->mach;
        case SLFlightProfileGraphTypeDrag:
            return [SLUnitsConvertor displayUnitsOf:dataPoint->drag forKey:THRUST_UNIT_KEY];
    }
}

#pragma mark - SLCurveGraphViewDelegate methods

-(NSUInteger)numberOfVerticalDivisions:(SLCurveGraphView *)sender{
    return 5;
}

-(BOOL)shouldDisplayMachOneLine:(SLCurveGraphView *)sender{
    return ((SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex] == SLFlightProfileGraphTypeMach);
}

#pragma mark - View Lifecycle

-(void)viewDidLoad{
    [super viewDidLoad];
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
    [backgroundView setImage:backgroundImage];
    [self.view insertSubview:backgroundView atIndex:0];
    [self.graphTypeSegmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor} forState:UIControlStateNormal];
    [self.graphTypeSegmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.blackColor} forState:UIControlStateSelected];
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:YES animated:YES];
    self.velocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    self.altitudeUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    self.graphView.dataSource = self;
    self.graphView.delegate = self;
    
    [self updateDisplay];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserverForName:SmartLaunchDidUpdateModelNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note){
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [self updateDisplay];
                                                      });
                                                  }];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(NSString *)description{
    return @"FlightProfileViewController";
}

@end
