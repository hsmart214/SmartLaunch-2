//
//  SLRocketPropertiesTVC.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLRocketPropertiesTVC.h"

#define DELETE_BUTTON_INDEX 2

@interface SLRocketPropertiesTVC ()<UIScrollViewDelegate, UIActionSheetDelegate, UITableViewDelegate>

@property (weak, nonatomic) UIScrollView *scrollView;
@property (nonatomic, weak) UITextField *activeField;
@property (nonatomic, strong) Rocket *oldRocket;
@property (nonatomic, strong) NSArray *validMotorDiameters;
@property (weak, nonatomic) IBOutlet UILabel *calculatedCdLabel;
@property (weak, nonatomic) IBOutlet UIStepper *motorDiamStepper;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *calcCdButton;

@end

@implementation SLRocketPropertiesTVC

- (NSArray *)validMotorDiameters{
    if (!_validMotorDiameters){
        _validMotorDiameters = [NSArray arrayWithObjects:
                                [NSNumber numberWithInteger:6],
                                [NSNumber numberWithInteger:13],
                                [NSNumber numberWithInteger:18],
                                [NSNumber numberWithInteger:24],
                                [NSNumber numberWithInteger:29],
                                [NSNumber numberWithInteger:38],
                                [NSNumber numberWithInteger:54],
                                [NSNumber numberWithInteger:66],
                                [NSNumber numberWithInteger:75],
                                [NSNumber numberWithInteger:98],
                                [NSNumber numberWithInteger:150],
                                nil];
    }
    return _validMotorDiameters;
}

- (BOOL)isValidRocket{
    BOOL valid = YES;
    valid = valid && ([self.nameField.text length] != 0);
    valid = valid && ([self.massField.text length] != 0);
    valid = valid && ([self.diamField.text length] != 0);
    valid = valid && ([self.motorDiamLabel.text length] != 0);
    valid = valid && ([self.cdField.text floatValue] > 0);
    return valid;
}

- (void)updateRocket{
    self.rocket.name = self.nameField.text;
    self.rocket.kitName = self.kitNameField.text;
    self.rocket.manufacturer = self.manField.text;
    self.rocket.mass = [SLUnitsConvertor metricStandardOf:
                        [NSNumber numberWithFloat:fabsf([self.massField.text floatValue])] forKey:MASS_UNIT_KEY];
    self.rocket.diameter = [SLUnitsConvertor metricStandardOf:
                            [NSNumber numberWithFloat:fabsf([self.diamField.text floatValue])] forKey:DIAM_UNIT_KEY];
    self.rocket.length = [SLUnitsConvertor metricStandardOf:
                          [NSNumber numberWithFloat:fabsf([self.lenField.text floatValue])] forKey:LENGTH_UNIT_KEY];
    self.rocket.cd = [NSNumber numberWithFloat:fabsf([self.cdField.text floatValue])];
    NSInteger motorDiam = [self.motorDiamLabel.text integerValue];
    self.rocket.motorSize = [NSNumber numberWithInteger:motorDiam];
    [self.saveButton setEnabled:[self isValidRocket]];
}

- (void)calculateCd{
    float total = 0.0;
    for (NSDictionary *flight in self.rocket.recordedFlights){
        total += [flight[FLIGHT_BEST_CD]floatValue];
    }
    NSInteger numFlights = MAX([self.rocket.recordedFlights count], 1);
    self.calculatedCdLabel.text = [NSString stringWithFormat:@"%1.2f", total/numFlights];
    //enable the "UseCalcCd" button only if there IS a calc Cd to use
    [self.calcCdButton setEnabled:(total != 0.0)];
}

- (IBAction)useCalculatedCd:(UIBarButtonItem *)sender {
    self.cdField.text = self.calculatedCdLabel.text;
    [self updateRocket];
}

- (void)updateDisplay{
    self.nameField.text = self.rocket.name;
    self.kitNameField.text = self.rocket.kitName;
    self.manField.text = self.rocket.manufacturer;
    NSNumber *temp = [SLUnitsConvertor displayUnitsOf:self.rocket.mass forKey:MASS_UNIT_KEY];
    self.massField.text = [NSString stringWithFormat:@"%2.2f", [temp floatValue]];
    temp = [SLUnitsConvertor displayUnitsOf:self.rocket.diameter forKey:DIAM_UNIT_KEY];
    self.diamField.text = [NSString stringWithFormat:@"%2.2f", [temp floatValue]];
    temp = [SLUnitsConvertor displayUnitsOf:self.rocket.length forKey:LENGTH_UNIT_KEY];
    self.lenField.text = [NSString stringWithFormat:@"%2.2f", [temp floatValue]];
    self.cdField.text = [NSString stringWithFormat:@"%2.2f", [self.rocket.cd floatValue]];
    self.motorDiamLabel.text = [NSString stringWithFormat:@"%d", [self.rocket.motorSize integerValue]];
    self.motorDiamStepper.value = [self.rocket.motorSize integerValue];
    [self calculateCd];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    if (!_rocket){
        _rocket = [[Rocket alloc] init];
        self.motorDiamStepper.value = [self.motorDiamStepper minimumValue];
        self.motorDiamLabel.text = [NSString stringWithFormat:@"%1.0f", self.motorDiamStepper.value];
        _rocket.motorSize = [NSNumber numberWithInteger:6];
    }else {
        self.oldRocket = [self.rocket copy];    // in case we need to delete this Rocket* later
    }
        
    // set up the unit labels based on user preferences
    self.motorDiamUnitsLabel.text = [SLUnitsConvertor displayStringForKey:MOTOR_SIZE_UNIT_KEY];
    self.massUnitsLabel.text = [SLUnitsConvertor displayStringForKey:MASS_UNIT_KEY];
    self.lenUnitsLabel.text = [SLUnitsConvertor displayStringForKey:LENGTH_UNIT_KEY];
    self.diamUnitsLabel.text = [SLUnitsConvertor displayStringForKey:DIAM_UNIT_KEY];
    
    self.nameField.delegate = self;
    self.kitNameField.delegate = self;
    self.manField.delegate = self;
    self.massField.delegate = self;
    self.diamField.delegate = self;
    self.lenField.delegate = self;
    self.cdField.delegate = self;
    
    [self updateDisplay];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return NO;
        //        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return NO;
    }
}


#pragma mark - UITextFieldDelegate methods

- (IBAction)textEditingDidBegin:(UITextField *)sender {
    self.activeField = sender;
}


- (IBAction)textEditingDidEnd:(UITextField *)sender {
    [sender resignFirstResponder];
    self.activeField = nil;
    [self updateRocket];
}

- (IBAction)textEditingDidEndOnExit:(UITextField *)sender {
    [self textEditingDidEnd:sender];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - UIStepper method

- (IBAction)motorDiameterChanged:(UIStepper *)sender {
    NSInteger mmt = [self.motorDiamLabel.text integerValue];
    float direction = sender.value - mmt;
    NSInteger newSize = 0;
    if (direction > 0){
        // increment motor size to next larger valid size
        for (int i=0; i < [self.validMotorDiameters count]; i++){
            if ([[self.validMotorDiameters objectAtIndex:i]integerValue] == mmt){
                newSize = [[self.validMotorDiameters objectAtIndex:i+1] integerValue];
                break;
            }
        }
    }else{
        // decrement motor size to next smaller valid size
        for (int i=0; i < [self.validMotorDiameters count]; i++){
            if ([[self.validMotorDiameters objectAtIndex:i]integerValue] == mmt){
                newSize = [[self.validMotorDiameters objectAtIndex:i-1] integerValue];
                break;
            }
        }
    }
    sender.value = newSize;
    self.motorDiamLabel.text = [NSString stringWithFormat:@"%d", newSize];
    [self updateRocket];
}

#pragma mark - Save/Delete/Cancel actions

- (IBAction)saveButtonPressed:(UIBarButtonItem *)sender {
    [self.delegate SLRocketPropertiesTVC: self savedRocket:self.rocket];
    [self.navigationController popViewControllerAnimated:YES];
}


// pop back without saving
- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    if (self.oldRocket)[self.delegate SLRocketPropertiesTVC:self savedRocket:self.oldRocket];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDelegate method

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - SLSavedFlightsDelegate method

-(void)SLSavedFlightsTVC:(id)sender didUpdateSavedFlights:(NSArray *)savedFlights{
    self.rocket.recordedFlights = savedFlights;
    [self calculateCd];
}

#pragma mark - prepareForSegue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"savedFlightsSegue"]){
        //pass on the model for the next table view controller
        [(SLSavedFlightsTVC *)segue.destinationViewController setSavedFlights:self.rocket.recordedFlights];
    }
}

@end
