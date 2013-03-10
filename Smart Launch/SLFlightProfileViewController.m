//
//  SLFlightProfileViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 2/3/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLFlightProfileViewController.h"
#import "SLUnitsConvertor.h"

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
    self.motorNameLabel.text = [self.dataSource motorName];
    self.maxVelocityLabel.text = [NSString stringWithFormat:@"%1.0f",[[SLUnitsConvertor displayUnitsOf:[self.dataSource maxVelocity] forKey:VELOCITY_UNIT_KEY] floatValue]];
    self.apogeeLabel.text = [NSString stringWithFormat:@"%1.0f",[[SLUnitsConvertor displayUnitsOf:[self.dataSource apogeeAltitude] forKey:ALT_UNIT_KEY] floatValue]];
    self.coastTimeLabel.text = [NSString stringWithFormat:@"%1.1f",[[self.dataSource coastTime] floatValue]];
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
}

-(CGFloat)curveGraphViewDataValueMinimumValue:(SLCurveGraphView *)sender{
    if ([self.graphTypeSegmentedControl selectedSegmentIndex] == SLFlightProfileGraphTypeAcceleration){
        return [[SLUnitsConvertor displayUnitsOf:[self.dataSource maxDeceleration] forKey:ACCEL_UNIT_KEY] floatValue];
    }else{
        return 0.0;
    }
}

-(CGFloat)curveGraphViewTimeValueRange:(SLCurveGraphView *)sender{
    return [[self.dataSource totalTime] floatValue];
}

-(CGFloat)curveGraphView:(SLCurveGraphView *)thrustCurveView dataValueForTimeIndex:(CGFloat)timeIndex{
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
}

#pragma mark - SLCurveGraphViewDelegate methods

-(NSUInteger)numberOfVerticalDivisions:(SLCurveGraphView *)sender{
    return 5;
}

-(BOOL)shouldDisplayMachOneLine:(SLCurveGraphView *)sender{
    return ((enum SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex] == SLFlightProfileGraphTypeMach);
}

#pragma mark - View Lifecycle

-(void)viewDidLoad{
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
    [backgroundView setImage:backgroundImage];
    [self.view insertSubview:backgroundView atIndex:0];
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:YES animated:YES];
    self.velocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    self.altitudeUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    self.graphView.dataSource = self;
    self.graphView.delegate = self;
    
    [self updateDisplay];
}
@end
