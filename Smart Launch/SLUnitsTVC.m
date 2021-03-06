//
//  SLUnitsTVC.m
//  Smart Launch
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
@property (weak, nonatomic) IBOutlet UISegmentedControl *accelControl;

@property (strong, nonatomic) NSDictionary *oldPrefs;

@end

@implementation SLUnitsTVC

- (IBAction)saveButtonPressed:(UIBarButtonItem *)sender {
    
    [self.delegate didChangeUnitPrefs:self];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)defaultButtonPressed:(UIBarButtonItem *)sender {
    NSString *msg = NSLocalizedString(@"Reset Default Units?", @"Reset Default Units?");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *act){
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           [alert.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                                       });
                                                   }];
    [alert addAction:action];
    action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Metric", @"Metric")
                                      style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction *act){
                                        [SLUnitsTVC setMetricDefaults];
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [alert.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                        });
                                    }];
    [alert addAction:action];
    action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Standard", @"Standard")
                                      style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction *act){
                                        [SLUnitsTVC setStandardDefaults];
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [alert.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                        });
                                    }];
    [alert addAction:action];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
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
            break;
        case 2:
            newPrefs[VELOCITY_UNIT_KEY] = K_KPH;
    }
    switch (self.thrustControl.selectedSegmentIndex) {
        case 0:
            newPrefs[THRUST_UNIT_KEY] = K_POUNDS;
            break;
        case 1:
            newPrefs[THRUST_UNIT_KEY] = K_NEWTONS;
    }
    switch (self.accelControl.selectedSegmentIndex) {
        case 0:
            newPrefs[ACCEL_UNIT_KEY] = K_GRAVITIES;
            break;
        case 1:
            newPrefs[ACCEL_UNIT_KEY] = K_M_PER_SEC_SQ;
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
    }else if ([unitPrefs[VELOCITY_UNIT_KEY] isEqualToString:K_METER_PER_SEC]){
        [self.velocityControl setSelectedSegmentIndex:1];
    }else{// must be km/hr
        [self.velocityControl setSelectedSegmentIndex:2];
    }
    if ([unitPrefs[THRUST_UNIT_KEY] isEqualToString:K_POUNDS]) {
        [self.thrustControl setSelectedSegmentIndex:0];
    }else{//must be newtons
        [self.thrustControl setSelectedSegmentIndex:1];
    }
    if ([unitPrefs[ACCEL_UNIT_KEY] isEqualToString:K_GRAVITIES]) {
        [self.accelControl setSelectedSegmentIndex:0];
    }else{//must be meters/sec^2
        [self.accelControl setSelectedSegmentIndex:1];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        //self.tableView.backgroundColor = [SLCustomUI iPadBackgroundColor];
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_FOR_IPAD_MASTER_VC];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }else{
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.oldPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    [self updateDisplay];
}

-(void)dealloc{
    self.oldPrefs = nil;
}

#pragma mark - UITableViewDelegate method

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return [SLCustomUI headerHeight];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    NSString *headerText;
    if (section == 0){
        headerText = NSLocalizedString(@"Rocket", @"Rocket");
    }else{  // must be last section - there are only three
        headerText = NSLocalizedString(@"Simulation", @"Simulation");
    }
    UILabel *headerLabel = [[UILabel alloc] init];
    [headerLabel setTextColor:[SLCustomUI headerTextColor]];
    [headerLabel setBackgroundColor:self.tableView.backgroundColor];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setText:headerText];
    [headerLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
    
    
    return headerLabel;
}

+(void)setMetricDefaults{
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:metricDefaults forKey:UNIT_PREFS_KEY];
    [defaults synchronize];
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

-(NSString *)description{
    return @"UnitsTVC";
}

@end
