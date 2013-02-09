//
//  SLUnitsTVC.m
//  Snoopy
//
//  Created by J. Howard Smart on 7/4/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLUnitsTVC.h"

@interface SLUnitsTVC ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *diamControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *lengthControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *massControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *tempControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *altitudeControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *velocityControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *thrustControl;

@property (strong, nonatomic) NSDictionary *oldPrefs;

@end

@implementation SLUnitsTVC

- (IBAction)saveButtonPressed:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)defaultButtonPressed:(UIBarButtonItem *)sender {
    NSString *msg = @"Reset Default Units?";
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:msg delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles: @"Metric", @"Standard", nil];
    [actionSheet showFromToolbar:self.navigationController.toolbar];
}
- (IBAction)revertButtonPressed:(UIBarButtonItem *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.oldPrefs forKey:UNIT_PREFS_KEY];
    [defaults synchronize];
    [self updateDisplay];
}

- (IBAction)controlValueChanged:(UISegmentedControl *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *newPrefs = [[defaults objectForKey:UNIT_PREFS_KEY]mutableCopy];
    switch (self.diamControl.selectedSegmentIndex) {
        case 0:
            newPrefs[DIAM_UNIT_KEY] = K_INCHES;
            break;
        case 1:
            newPrefs[DIAM_UNIT_KEY] = K_MILLIMETERS;
    }
    switch (self.lengthControl.selectedSegmentIndex) {
        case 0:
            newPrefs[LENGTH_UNIT_KEY] = K_INCHES;
            break;
        case 1:
            newPrefs[LENGTH_UNIT_KEY] = K_FEET;
            break;
        case 2:
            newPrefs[LENGTH_UNIT_KEY] = K_METERS;
    }
    switch (self.massControl.selectedSegmentIndex) {
        case 0:
            newPrefs[MASS_UNIT_KEY] = K_OUNCES;
            break;
        case 1:
            newPrefs[MASS_UNIT_KEY] = K_POUNDS;
            break;
        case 2:
            newPrefs[MASS_UNIT_KEY] = K_KILOGRAMS;
    }
    switch (self.tempControl.selectedSegmentIndex) {
        case 0:
            newPrefs[TEMP_UNIT_KEY] = K_FAHRENHEIT;
            break;
        case 1:
            newPrefs[TEMP_UNIT_KEY] = K_CELSIUS;
    }
    switch (self.altitudeControl.selectedSegmentIndex) {
        case 0:
            newPrefs[ALT_UNIT_KEY] = K_FEET;
            break;
        case 1:
            newPrefs[ALT_UNIT_KEY] = K_METERS;
    }
    switch (self.velocityControl.selectedSegmentIndex) {
        case 0:
            newPrefs[VELOCITY_UNIT_KEY] = K_MILES_PER_HOUR;
            break;
        case 1:
            newPrefs[VELOCITY_UNIT_KEY] = K_METER_PER_SEC;
    }
    switch (self.thrustControl.selectedSegmentIndex) {
        case 0:
            newPrefs[THRUST_UNIT_KEY] = K_POUNDS;
            break;
        case 1:
            newPrefs[THRUST_UNIT_KEY] = K_NEWTONS;
    }
    [defaults setObject:newPrefs forKey:UNIT_PREFS_KEY];
    [defaults synchronize];
}

- (void)updateDisplay{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *unitPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    if ([unitPrefs[DIAM_UNIT_KEY] isEqualToString:K_INCHES]){
        [self.diamControl setSelectedSegmentIndex:0];
    }else{//must be mm
        [self.diamControl setSelectedSegmentIndex:1];
    }
    if ([unitPrefs[LENGTH_UNIT_KEY] isEqualToString:K_INCHES]){
        [self.lengthControl setSelectedSegmentIndex:0];
    }else if ([unitPrefs[LENGTH_UNIT_KEY] isEqualToString:K_FEET]){
        [self.lengthControl setSelectedSegmentIndex:1];
    }else{//must be meters
        [self.lengthControl setSelectedSegmentIndex:2];
    }
    if ([unitPrefs[MASS_UNIT_KEY] isEqualToString:K_OUNCES]){
        [self.massControl setSelectedSegmentIndex:0];
    }else if ([unitPrefs[MASS_UNIT_KEY] isEqualToString:K_POUNDS]){
        [self.massControl setSelectedSegmentIndex:1];
    }else{//must be kilos
        [self.massControl setSelectedSegmentIndex:2];
    }
    if ([unitPrefs[TEMP_UNIT_KEY] isEqualToString:K_FAHRENHEIT]){
        [self.tempControl setSelectedSegmentIndex:0];
    }else{//must be celsius
        [self.tempControl setSelectedSegmentIndex:1];
    }
    if ([unitPrefs[ALT_UNIT_KEY] isEqualToString:K_FEET]){
        [self.altitudeControl setSelectedSegmentIndex:0];
    }else{//must be meters
        [self.altitudeControl setSelectedSegmentIndex:1];
    }
    if ([unitPrefs[VELOCITY_UNIT_KEY] isEqualToString:K_MILES_PER_HOUR]){
        [self.velocityControl setSelectedSegmentIndex:0];
    }else{//must be meters/sec
        [self.velocityControl setSelectedSegmentIndex:1];
    }
    if ([unitPrefs[THRUST_UNIT_KEY] isEqualToString:K_POUNDS]) {
        [self.thrustControl setSelectedSegmentIndex:0];
    }else{//must be newtons
        [self.thrustControl setSelectedSegmentIndex:1];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.oldPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    [self updateDisplay];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableViewDelegate method

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIActionSheetDelegate method

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSDictionary *metricDefaults = @{MOTOR_SIZE_UNIT_KEY: K_MILLIMETERS,
                                    DIAM_UNIT_KEY: K_MILLIMETERS,
                                    LENGTH_UNIT_KEY: K_METERS,
                                    MASS_UNIT_KEY: K_KILOGRAMS,
                                    TEMP_UNIT_KEY: K_CELSIUS,
                                    ALT_UNIT_KEY: K_METERS,
                                    VELOCITY_UNIT_KEY: K_METER_PER_SEC,
                                    THRUST_UNIT_KEY: K_NEWTONS,
                                    ACCEL_UNIT_KEY: K_M_PER_SEC_SQ,
                                    MACH_UNIT_KEY: K_MACH};
    NSDictionary *standardDefaults = @{MOTOR_SIZE_UNIT_KEY: K_MILLIMETERS,
                                      DIAM_UNIT_KEY: K_INCHES,
                                      LENGTH_UNIT_KEY: K_INCHES,
                                      MASS_UNIT_KEY: K_POUNDS,
                                      TEMP_UNIT_KEY: K_FAHRENHEIT,
                                      ALT_UNIT_KEY: K_FEET,
                                      VELOCITY_UNIT_KEY: K_MILES_PER_HOUR,
                                      THRUST_UNIT_KEY: K_POUNDS,
                                      ACCEL_UNIT_KEY: K_GRAVITIES,
                                      MACH_UNIT_KEY: K_MACH};
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    switch (buttonIndex) {
        case 0://metric
            [defaults setObject:metricDefaults forKey:UNIT_PREFS_KEY];
            [defaults synchronize];
            break;
        case 1:
            [defaults setObject:standardDefaults forKey:UNIT_PREFS_KEY];
            [defaults synchronize];
            break;
        default:
            break;
    }
    [self updateDisplay];
}

+(void)setStandardDefaults{
    NSDictionary *stdDefaults = @{MOTOR_SIZE_UNIT_KEY: K_MILLIMETERS,
                                 DIAM_UNIT_KEY: K_INCHES,
                                 LENGTH_UNIT_KEY: K_INCHES,
                                 MASS_UNIT_KEY: K_POUNDS,
                                 TEMP_UNIT_KEY: K_FAHRENHEIT,
                                 ALT_UNIT_KEY: K_FEET,
                                 VELOCITY_UNIT_KEY: K_MILES_PER_HOUR,
                                 THRUST_UNIT_KEY: K_POUNDS,
                                 ACCEL_UNIT_KEY: K_GRAVITIES,
                                 MACH_UNIT_KEY: K_MACH};
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:stdDefaults forKey:UNIT_PREFS_KEY];
    [defaults synchronize];
}

@end
