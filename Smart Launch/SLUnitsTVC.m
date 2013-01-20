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
@synthesize diamControl = _diamControl;
@synthesize lengthControl = _lengthControl;
@synthesize massControl = _massControl;
@synthesize tempControl = _tempControl;
@synthesize altitudeControl = _altitudeControl;
@synthesize velocityControl = _velocityControl;
@synthesize thrustControl = _thrustControl;
@synthesize oldPrefs = _oldPrefs;

- (IBAction)saveButtonPressed:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)defaultButtonPressed:(UIBarButtonItem *)sender {
    NSString *msg = @"Reset Default Units?";
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:msg delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles: @"Metric", @"Standard", nil];
    [actionSheet showFromToolbar:self.navigationController.toolbar];
}
- (IBAction)revertButtonPressed:(UIBarButtonItem *)sender {
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *defaults = [NSUbiquitousKeyValueStore defaultStore];
    [defaults setObject:self.oldPrefs forKey:UNIT_PREFS_KEY];
    [defaults synchronize];
    [self updateDisplay];
}

- (IBAction)controlValueChanged:(UISegmentedControl *)sender {
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *defaults = [NSUbiquitousKeyValueStore defaultStore];
    NSMutableDictionary *newPrefs = [[defaults objectForKey:UNIT_PREFS_KEY]mutableCopy];
    switch (self.diamControl.selectedSegmentIndex) {
        case 0:
            [newPrefs setObject:K_INCHES forKey:DIAM_UNIT_KEY];
            break;
        case 1:
            [newPrefs setObject:K_MILLIMETERS forKey:DIAM_UNIT_KEY];
    }
    switch (self.lengthControl.selectedSegmentIndex) {
        case 0:
            [newPrefs setObject:K_INCHES forKey:LENGTH_UNIT_KEY];
            break;
        case 1:
            [newPrefs setObject:K_FEET forKey:LENGTH_UNIT_KEY];
            break;
        case 2:
            [newPrefs setObject:K_METERS forKey:LENGTH_UNIT_KEY];
    }
    switch (self.massControl.selectedSegmentIndex) {
        case 0:
            [newPrefs setObject:K_OUNCES forKey:MASS_UNIT_KEY];
            break;
        case 1:
            [newPrefs setObject:K_POUNDS forKey:MASS_UNIT_KEY];
            break;
        case 2:
            [newPrefs setObject:K_KILOGRAMS forKey:MASS_UNIT_KEY];
    }
    switch (self.tempControl.selectedSegmentIndex) {
        case 0:
            [newPrefs setObject:K_FAHRENHEIT forKey:TEMP_UNIT_KEY];
            break;
        case 1:
            [newPrefs setObject:K_CELSIUS forKey:TEMP_UNIT_KEY];
    }
    switch (self.altitudeControl.selectedSegmentIndex) {
        case 0:
            [newPrefs setObject:K_FEET forKey:ALT_UNIT_KEY];
            break;
        case 1:
            [newPrefs setObject:K_METERS forKey:ALT_UNIT_KEY];
    }
    switch (self.velocityControl.selectedSegmentIndex) {
        case 0:
            [newPrefs setObject:K_MILES_PER_HOUR forKey:VELOCITY_UNIT_KEY];
            break;
        case 1:
            [newPrefs setObject:K_METER_PER_SEC forKey:VELOCITY_UNIT_KEY];
    }
    switch (self.thrustControl.selectedSegmentIndex) {
        case 0:
            [newPrefs setObject:K_POUNDS forKey:THRUST_UNIT_KEY];
            break;
        case 1:
            [newPrefs setObject:K_NEWTONS forKey:THRUST_UNIT_KEY];
    }
    [defaults setObject:newPrefs forKey:UNIT_PREFS_KEY];
    [defaults synchronize];
}

- (void)updateDisplay{
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *defaults = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *unitPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    if ([[unitPrefs objectForKey:DIAM_UNIT_KEY] isEqualToString:K_INCHES]){
        [self.diamControl setSelectedSegmentIndex:0];
    }else{//must be mm
        [self.diamControl setSelectedSegmentIndex:1];
    }
    if ([[unitPrefs objectForKey:LENGTH_UNIT_KEY] isEqualToString:K_INCHES]){
        [self.lengthControl setSelectedSegmentIndex:0];
    }else if ([[unitPrefs objectForKey:LENGTH_UNIT_KEY] isEqualToString:K_FEET]){
        [self.lengthControl setSelectedSegmentIndex:1];
    }else{//must be meters
        [self.lengthControl setSelectedSegmentIndex:2];
    }
    if ([[unitPrefs objectForKey:MASS_UNIT_KEY] isEqualToString:K_OUNCES]){
        [self.massControl setSelectedSegmentIndex:0];
    }else if ([[unitPrefs objectForKey:MASS_UNIT_KEY] isEqualToString:K_POUNDS]){
        [self.massControl setSelectedSegmentIndex:1];
    }else{//must be kilos
        [self.massControl setSelectedSegmentIndex:2];
    }
    if ([[unitPrefs objectForKey:TEMP_UNIT_KEY] isEqualToString:K_FAHRENHEIT]){
        [self.tempControl setSelectedSegmentIndex:0];
    }else{//must be celsius
        [self.tempControl setSelectedSegmentIndex:1];
    }
    if ([[unitPrefs objectForKey:ALT_UNIT_KEY] isEqualToString:K_FEET]){
        [self.altitudeControl setSelectedSegmentIndex:0];
    }else{//must be meters
        [self.altitudeControl setSelectedSegmentIndex:1];
    }
    if ([[unitPrefs objectForKey:VELOCITY_UNIT_KEY] isEqualToString:K_MILES_PER_HOUR]){
        [self.velocityControl setSelectedSegmentIndex:0];
    }else{//must be meters/sec
        [self.velocityControl setSelectedSegmentIndex:1];
    }
    if ([[unitPrefs objectForKey:THRUST_UNIT_KEY] isEqualToString:K_POUNDS]) {
        [self.thrustControl setSelectedSegmentIndex:0];
    }else{//must be newtons
        [self.thrustControl setSelectedSegmentIndex:1];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *defaults = [NSUbiquitousKeyValueStore defaultStore];
    self.oldPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    [self updateDisplay];
}

- (void)viewDidUnload
{
    [self setDiamControl:nil];
    [self setLengthControl:nil];
    [self setMassControl:nil];
    [self setTempControl:nil];
    [self setAltitudeControl:nil];
    [self setVelocityControl:nil];
    [self setThrustControl:nil];
    self.oldPrefs = nil;
    [super viewDidUnload];
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
    NSDictionary *metricDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                    K_MILLIMETERS, MOTOR_SIZE_UNIT_KEY,
                                    K_MILLIMETERS, DIAM_UNIT_KEY,
                                    K_METERS, LENGTH_UNIT_KEY,
                                    K_KILOGRAMS, MASS_UNIT_KEY,
                                    K_CELSIUS, TEMP_UNIT_KEY,
                                    K_METERS, ALT_UNIT_KEY,
                                    K_METER_PER_SEC, VELOCITY_UNIT_KEY,
                                    K_NEWTONS, THRUST_UNIT_KEY, nil];
    NSDictionary *standardDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                      K_MILLIMETERS, MOTOR_SIZE_UNIT_KEY,
                                      K_INCHES, DIAM_UNIT_KEY,
                                      K_INCHES, LENGTH_UNIT_KEY,
                                      K_POUNDS, MASS_UNIT_KEY,
                                      K_FAHRENHEIT, TEMP_UNIT_KEY,
                                      K_FEET, ALT_UNIT_KEY,
                                      K_MILES_PER_HOUR, VELOCITY_UNIT_KEY,
                                      K_POUNDS, THRUST_UNIT_KEY, nil];
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *defaults = [NSUbiquitousKeyValueStore defaultStore];
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
    NSDictionary *stdDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                      K_MILLIMETERS, MOTOR_SIZE_UNIT_KEY,
                                      K_INCHES, DIAM_UNIT_KEY,
                                      K_INCHES, LENGTH_UNIT_KEY,
                                      K_POUNDS, MASS_UNIT_KEY,
                                      K_FAHRENHEIT, TEMP_UNIT_KEY,
                                      K_FEET, ALT_UNIT_KEY,
                                      K_MILES_PER_HOUR, VELOCITY_UNIT_KEY,
                                      K_POUNDS, THRUST_UNIT_KEY, nil];
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *defaults = [NSUbiquitousKeyValueStore defaultStore];
    [defaults setDictionary:stdDefaults forKey:UNIT_PREFS_KEY];
    [defaults synchronize];
}

@end
