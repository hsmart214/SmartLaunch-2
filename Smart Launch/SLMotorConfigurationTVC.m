//
//  SLMotorConfigurationTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/23/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLMotorConfigurationTVC.h"
#import "RocketMotor.h"

@interface SLMotorConfigurationTVC ()
@property (weak, nonatomic) IBOutlet UILabel *centralLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *firstGroupCount;
@property (weak, nonatomic) IBOutlet UISegmentedControl *secondGroupCount;
@property (weak, nonatomic) IBOutlet UISegmentedControl *thirdGroupCount;
@property (weak, nonatomic) IBOutlet UILabel *firstGroupSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondGroupSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdGroupSizeLabel;
@property (strong, nonatomic) IBOutletCollection(UIStepper) NSArray *sizeSteppers;
@property (weak, nonatomic) IBOutlet UIStepper *centralStepper;
@property (weak, nonatomic) IBOutlet UIStepper *firstGroupStepper;
@property (weak, nonatomic) IBOutlet UIStepper *secondGroupStepper;
@property (weak, nonatomic) IBOutlet UIStepper *thridGroupStepper;

@property (nonatomic, strong) NSMutableArray *workingConfiguration;
@property (nonatomic, strong) NSArray *oldConfiguration;

@end

@implementation SLMotorConfigurationTVC

-(NSMutableArray *)workingConfiguration{
    if (!_workingConfiguration){
        _workingConfiguration = [NSMutableArray array];
    }
    return _workingConfiguration;
}

- (IBAction)firstGroupCountChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0){
        self.firstGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
        [self.firstGroupStepper setValue:0];
        [self.firstGroupStepper setEnabled:NO];
        self.secondGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
        [self.secondGroupStepper setValue:0];
        [self.secondGroupStepper setEnabled:NO];
        self.secondGroupCount.selectedSegmentIndex = 0;
        [self.secondGroupCount setEnabled:NO];
        self.thirdGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
        [self.thridGroupStepper setValue:0];
        [self.thridGroupStepper setEnabled:NO];
        self.thirdGroupCount.selectedSegmentIndex = 0;
        [self.thirdGroupCount setEnabled:NO];
    }else{
        [self.firstGroupStepper setEnabled:YES];
    }
    [self updateDisplay];
}

- (IBAction)secondGroupCountChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0){
        self.secondGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
        [self.secondGroupStepper setValue:0];
        [self.secondGroupStepper setEnabled:NO];
        self.thirdGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
        [self.thridGroupStepper setValue:0];
        [self.thridGroupStepper setEnabled:NO];
        self.thirdGroupCount.selectedSegmentIndex = 0;
        [self.thirdGroupCount setEnabled:NO];
    }else{
        [self.secondGroupStepper setEnabled:YES];
    }
    [self updateDisplay];
}

- (IBAction)thirdGroupCountChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0){
        self.thirdGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
        [self.thridGroupStepper setValue:0];
        [self.thridGroupStepper setEnabled:NO];
    }else{
        [self.thridGroupStepper setEnabled:YES];
    }
    [self updateDisplay];
}

- (IBAction)centralStepperChanged:(UIStepper *)sender {
    NSInteger index = (int)round(sender.value);
    if (!index){
        self.centralLabel.text = NSLocalizedString(@"None", @"There is no motor");
    }else{
        index--;    // this is because the stepper value is one above the index in the array
        self.centralLabel.text = [RocketMotor motorDiameters][index];
    }
    [self updateDisplay];
}

- (IBAction)firstStepperChanged:(UIStepper *)sender {
    NSInteger index = (int)round(sender.value);
    if (!index){
        self.firstGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
        self.secondGroupCount.selectedSegmentIndex = 0;
        [self.secondGroupCount setEnabled:NO];
        self.secondGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
        [self.secondGroupStepper setValue:0.0];
        [self.secondGroupStepper setEnabled:NO];
        self.thirdGroupCount.selectedSegmentIndex = 0;
        [self.thirdGroupCount setEnabled:NO];
        self.thirdGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
        [self.thridGroupStepper setValue:0.0];
        [self.thridGroupStepper setEnabled:NO];
    }else{
        index--;    // this is because the stepper value is one above the index in the array
        self.firstGroupSizeLabel.text = [RocketMotor motorDiameters][index];
        [self.secondGroupCount setEnabled:YES];
    }
    [self updateDisplay];
}

- (IBAction)secondStepperChanged:(UIStepper *)sender {
    NSInteger index = (int)round(sender.value);
    if (!index){
        self.secondGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
        self.thirdGroupCount.selectedSegmentIndex = 0;
        [self.thirdGroupCount setEnabled:NO];
        self.thirdGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
        [self.thridGroupStepper setValue:0.0];
        [self.thridGroupStepper setEnabled:NO];
    }else{
        index--;    // this is because the stepper value is one above the index in the array
        self.secondGroupSizeLabel.text = [RocketMotor motorDiameters][index];
        [self.thirdGroupCount setEnabled:YES];
    }
    [self updateDisplay];
}

- (IBAction)thirdStepperChanged:(UIStepper *)sender {
    NSInteger index = (int)round(sender.value);
    if (!index){
        self.thirdGroupSizeLabel.text = NSLocalizedString(@"None", @"There is no motor");
    }else{
        index--;    // this is because the stepper value is one above the index in the array
        self.thirdGroupSizeLabel.text = [RocketMotor motorDiameters][index];
    }
    [self updateDisplay];
}

- (IBAction)revertToOldConfiguration:(UIBarButtonItem *)sender {
    self.workingConfiguration = [self.oldConfiguration mutableCopy];
    [self updateDisplay];
}

-(NSUInteger)indexOfMotorSize:(NSUInteger)size{
    NSString *sizeStr = [NSString stringWithFormat:@"%dmm", size];
    NSArray *diams = [RocketMotor motorDiameters];
    for (int i = 0; i < [diams count]; i++){
        if ([diams[i] isEqualToString:sizeStr]) return i;
    }
    return 0;
}

-(void)updateWorkingConfig{
    NSMutableArray *array = [NSMutableArray array];
    if ([self.centralLabel.text integerValue]){
        [array addObject:@{MOTOR_COUNT_KEY: @1,
          MOTOR_DIAM_KEY: @([self.centralLabel.text integerValue])}];
    }
    if ([self.firstGroupSizeLabel.text integerValue]){
        [array addObject:@{MOTOR_COUNT_KEY: @(self.firstGroupCount.selectedSegmentIndex + 1),
                          MOTOR_DIAM_KEY: @([self.firstGroupSizeLabel.text integerValue])}];
    }
    if ([self.secondGroupSizeLabel.text integerValue]){
        [array addObject:@{MOTOR_COUNT_KEY: @(self.secondGroupCount.selectedSegmentIndex + 1),
          MOTOR_DIAM_KEY: @([self.secondGroupSizeLabel.text integerValue])}];
    }
    if ([self.thirdGroupSizeLabel.text integerValue]){
        [array addObject:@{MOTOR_COUNT_KEY: @(self.thirdGroupCount.selectedSegmentIndex + 1),
          MOTOR_DIAM_KEY: @([self.thirdGroupSizeLabel.text integerValue])}];
    }
    self.workingConfiguration = array;
}

-(void)updateDisplay{
    [self updateWorkingConfig];
    NSArray *motorConfig = self.workingConfiguration;
    if ([motorConfig count]){
        NSDictionary *group = motorConfig[0];
        if ([group[MOTOR_COUNT_KEY] integerValue] == 1){
            NSString* diamStr =[NSString stringWithFormat:@"%dmm", [group[MOTOR_DIAM_KEY] integerValue]];
            self.centralLabel.text = diamStr;
            NSUInteger index = [self indexOfMotorSize:[group[MOTOR_DIAM_KEY] integerValue]];
            [self.centralStepper setValue:(double)index + 1];
        }else{ // the first entry in the array is a GROUP not a single motor
            self.centralLabel.text = NSLocalizedString(@"None", @"There is no motor");
            [self.centralStepper setValue:0.0];
            // set up the first group
            self.firstGroupCount.selectedSegmentIndex = [group[MOTOR_COUNT_KEY] integerValue] - 1;
            self.firstGroupSizeLabel.text = [NSString stringWithFormat:@"%dmm", [group[MOTOR_DIAM_KEY] integerValue]];
            NSUInteger index = [self indexOfMotorSize:[group[MOTOR_DIAM_KEY] integerValue]];
            [self.firstGroupStepper setValue:(double)index + 1];
        }
    }
    if ([motorConfig count] > 1){
        NSDictionary *group = motorConfig[1];
        if ([motorConfig[0][MOTOR_COUNT_KEY] integerValue] == 1){
            //the first entry was a CENTRAL motor - this is the most common
            // set up the first group
            self.firstGroupCount.selectedSegmentIndex = [group[MOTOR_COUNT_KEY] integerValue] - 1;
            self.firstGroupSizeLabel.text = [NSString stringWithFormat:@"%dmm", [group[MOTOR_DIAM_KEY] integerValue]];
            NSUInteger index = [self indexOfMotorSize:[group[MOTOR_DIAM_KEY] integerValue]];
            [self.firstGroupStepper setValue:(double)index + 1];
        }else{ // the first entry was the first GROUP
               // set up the second group
            self.secondGroupCount.selectedSegmentIndex = [group[MOTOR_COUNT_KEY] integerValue] - 1;
            self.secondGroupSizeLabel.text = [NSString stringWithFormat:@"%dmm", [group[MOTOR_DIAM_KEY] integerValue]];
            NSUInteger index = [self indexOfMotorSize:[group[MOTOR_DIAM_KEY] integerValue]];
            [self.secondGroupStepper setValue:(double)index + 1];
        }
    }
    if ([motorConfig count] > 2){
        NSDictionary *group = motorConfig[2];
        if ([motorConfig[0][MOTOR_COUNT_KEY] integerValue] == 1){
            //the first entry was a CENTRAL motor - this is the most common
            // set up the second group
            self.secondGroupCount.selectedSegmentIndex = [group[MOTOR_COUNT_KEY] integerValue] - 1;
            self.secondGroupSizeLabel.text = [NSString stringWithFormat:@"%dmm", [group[MOTOR_DIAM_KEY] integerValue]];
            NSUInteger index = [self indexOfMotorSize:[group[MOTOR_DIAM_KEY] integerValue]];
            [self.secondGroupStepper setValue:(double)index + 1];
        }else{ // the first entry was the first GROUP
               // set up the third group
            self.thirdGroupCount.selectedSegmentIndex = [group[MOTOR_COUNT_KEY] integerValue] - 1;
            self.thirdGroupSizeLabel.text = [NSString stringWithFormat:@"%dmm", [group[MOTOR_DIAM_KEY] integerValue]];
            NSUInteger index = [self indexOfMotorSize:[group[MOTOR_DIAM_KEY] integerValue]];
            [self.thridGroupStepper setValue:(double)index + 1];
        }
    }
    if ([motorConfig count] > 3){
        // this means all 4 groups have been used - this must be the last group
        NSDictionary *group = motorConfig[3];
        self.thirdGroupCount.selectedSegmentIndex = [group[MOTOR_COUNT_KEY] integerValue] - 1;
        self.thirdGroupSizeLabel.text = [NSString stringWithFormat:@"%dmm", [group[MOTOR_DIAM_KEY] integerValue]];
        NSUInteger index = [self indexOfMotorSize:[group[MOTOR_DIAM_KEY] integerValue]];
        [self.thridGroupStepper setValue:(double)index + 1];
    }
    NSUInteger lastGroupAvailable = [motorConfig count];
    if ([motorConfig count] && [motorConfig[0][MOTOR_COUNT_KEY] integerValue] != 1) lastGroupAvailable++;
    if (lastGroupAvailable <= 1){
        [self.secondGroupCount setEnabled:NO];
        [self.secondGroupStepper setEnabled:NO];
        [self.thridGroupStepper setEnabled:NO];
        [self.thirdGroupCount setEnabled:NO];
    }
    if (lastGroupAvailable == 2){
        [self.secondGroupCount setEnabled:YES];
        [self.secondGroupStepper setEnabled:YES];
        [self.thridGroupStepper setEnabled:NO];
        [self.thirdGroupCount setEnabled:NO];
    }
    if (lastGroupAvailable == 3){
        [self.secondGroupCount setEnabled:YES];
        [self.secondGroupStepper setEnabled:YES];
        [self.thridGroupStepper setEnabled:YES];
        [self.thirdGroupCount setEnabled:YES];
    }
    if (!self.firstGroupCount.selectedSegmentIndex) [self.firstGroupStepper setEnabled:NO];
    if (!self.secondGroupCount.selectedSegmentIndex) [self.secondGroupStepper setEnabled:NO];
    if (!self.thirdGroupCount.selectedSegmentIndex) [self.thridGroupStepper setEnabled:NO];
}

#pragma mark - View Life Cycle

-(void)viewDidLoad{
    [super viewDidLoad];
    for (UIStepper *stepper in self.sizeSteppers) {
        [stepper setMaximumValue:(double)[[RocketMotor motorDiameters] count]];
        [stepper setStepValue:1.0];
    }
    NSArray *motorConfig = [self.datasource currentMotorConfiguration];
    if (motorConfig) self.workingConfiguration = [motorConfig mutableCopy];
    self.oldConfiguration = motorConfig;
    [self updateDisplay];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.delegate SLMotorConfigurationTVC:self didChangeMotorConfiguration:[self.workingConfiguration copy]];
}

@end;