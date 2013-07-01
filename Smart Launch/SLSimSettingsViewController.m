//
//  SLSimSettingsViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/26/12.
//  Copyright (c) All rights reserved.
//

#import "SLSimSettingsViewController.h"

#define INITIAL_ROW_COUNT 7

@interface SLSimSettingsViewController ()<UITableViewDelegate, UITableViewDataSource, SLSimulationDelegate, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *launchAngleLabel;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityUnitsLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *windDirectionControl;
@property (weak, nonatomic) IBOutlet UIStepper *windVelocityStepper;
@property (weak, nonatomic) IBOutlet UILabel *launchGuideLengthLabel;
@property (weak, nonatomic) IBOutlet UILabel *launchGuideLengthUnitsLabel;
@property (weak, nonatomic) IBOutlet UIStepper *launchGuideLengthStepper;
@property (weak, nonatomic) IBOutlet UILabel *siteAltitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *siteAltitudeUnitsLabel;
@property (weak, nonatomic) IBOutlet UIStepper *siteAltitudeStepper;
@property (weak, nonatomic) IBOutlet UIButton *GPSAltButton;
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) NSString *launchGuideLengthFormatString;

@property (strong, nonatomic) NSMutableDictionary *settings;

@end

@implementation SLSimSettingsViewController

- (NSMutableDictionary *)settings{
    if (!_settings){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _settings = [[defaults objectForKey:SETTINGS_KEY] mutableCopy];
    }
    return _settings;
}

- (CLLocationManager *)locationManager{
    if (!_locationManager){
        _locationManager = [[CLLocationManager alloc] init];
//        _locationManager.purpose = NSLocalizedString(@"Only used to determine your altitude.", nil);
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (void)saveSettings{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.settings forKey:SETTINGS_KEY];
    [defaults synchronize];
    [self.delegate sender:self didChangeSimSettings:self.settings withUpdate:NO];
}

- (IBAction)windDirectionChanged:(UISegmentedControl *)sender {
    NSNumber *windDir = @(self.windDirectionControl.selectedSegmentIndex);
    (self.settings)[WIND_DIRECTION_KEY] = windDir;
    [self saveSettings];
}

- (IBAction)windVelocityChanged:(UIStepper *)sender {
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", sender.value];
}

- (IBAction)launchGuideLengthChanged:(UIStepper *)sender {
    self.launchGuideLengthLabel.text = [NSString stringWithFormat:self.launchGuideLengthFormatString, sender.value];
}

- (IBAction)siteAltitudeChanged:(UIStepper *)sender {
    //    double alt = sender.value;
    //    alt = floor(alt/self.alt_step) * self.alt_step;
    self.siteAltitudeLabel.text = [NSString stringWithFormat:@"%1.0f", sender.value];
}

- (IBAction)GPSAltitudeRequested:(UIButton *)sender {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
        [self.locationManager startUpdatingLocation];
    }
    
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    // If it's a relatively recent event, turn off updates to save power
    CLLocation *newLocation = [locations lastObject];
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
        float altGPSforDisplay = [SLUnitsConvertor displayUnitsOf:newLocation.altitude forKey:ALT_MSL_KEY];
        self.siteAltitudeLabel.text = [NSString stringWithFormat:@"%1.0f",altGPSforDisplay];
        self.siteAltitudeStepper.value = altGPSforDisplay;
        [self.locationManager stopUpdatingLocation];
    }
    // else skip the event and process the next one.
}

#pragma mark - SLSimulationDelegate method

- (void)sender:(id)sender didChangeLaunchAngle:(NSNumber *)launchAngle{
    (self.settings)[LAUNCH_ANGLE_KEY] = launchAngle;
    self.launchAngleLabel.text = [NSString stringWithFormat:@"%1.1f", [launchAngle floatValue] * DEGREES_PER_RADIAN];
    [self saveSettings];
}

#pragma mark - UITableViewDelegate/DataSource methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"launchAngleSegue"]){
        [[segue destinationViewController] setTitle:NSLocalizedString(@"Launch Angle", @"Launch Angle")];
        [[segue destinationViewController] setDelegate:self];
    }
}

#pragma mark - View lifecycle

-(void)setupUnits{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *unitPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    
    if ([unitPrefs[ALT_UNIT_KEY] isEqualToString:K_METERS]){
        [self.siteAltitudeStepper setMaximumValue:4000];
        self.siteAltitudeStepper.stepValue = 50;
    }else{// must be feet
        [self.siteAltitudeStepper setMaximumValue:10000];
        self.siteAltitudeStepper.stepValue = 100;
    }
    if ([unitPrefs[VELOCITY_UNIT_KEY] isEqualToString:K_MILES_PER_HOUR]){
        self.windVelocityStepper.maximumValue = 20;
        self.windVelocityStepper.stepValue = 1.0;
    }else if([unitPrefs[VELOCITY_UNIT_KEY] isEqualToString:K_KPH]){
        self.windVelocityStepper.maximumValue = 32;
        self.windVelocityStepper.stepValue = 1.0;
    }else{
        self.windVelocityStepper.maximumValue = 9;
        self.windVelocityStepper.stepValue = 0.5;
    }
    if ([unitPrefs[LENGTH_UNIT_KEY] isEqualToString:K_FEET]){
        self.launchGuideLengthFormatString = @"%1.1f";
        [self.launchGuideLengthStepper setMaximumValue:20];
        self.launchGuideLengthStepper.stepValue = 0.5;
        self.launchGuideLengthStepper.minimumValue = 0.5;
    }else if ([unitPrefs[LENGTH_UNIT_KEY] isEqualToString:K_INCHES]){
        self.launchGuideLengthFormatString = @"%1.0f";
        [self.launchGuideLengthStepper setMaximumValue:240];
        self.launchGuideLengthStepper.stepValue = 2.0;
        self.launchGuideLengthStepper.minimumValue = 4.0;
    }else{//must be meters
        self.launchGuideLengthFormatString = @"%1.1f";
        [self.launchGuideLengthStepper setMaximumValue:7];
        self.launchGuideLengthStepper.stepValue = 0.2;
        self.launchGuideLengthStepper.minimumValue = 0.2;
    }

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    [self.GPSAltButton setTitle: NSLocalizedString(@"GPS Disabled", @"GPS Disabled") forState:UIControlStateDisabled];
    if (!self.splitViewController){
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
    }
    // set up the unit labels for the preferred units
    
    self.windVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    self.launchGuideLengthUnitsLabel.text = [SLUnitsConvertor displayStringForKey:LENGTH_UNIT_KEY];
    self.siteAltitudeUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    
    [self setupUnits];
    
    float launchAngle = [(self.settings)[LAUNCH_ANGLE_KEY] floatValue];
    self.launchAngleLabel.text = [NSString stringWithFormat:@"%1.1f", launchAngle * DEGREES_PER_RADIAN];
    float windVelocity = [SLUnitsConvertor displayUnitsOf: [(self.settings)[WIND_VELOCITY_KEY] floatValue] forKey:VELOCITY_UNIT_KEY];
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", windVelocity];
    self.windVelocityStepper.value = windVelocity;
    float guideLength = [SLUnitsConvertor displayUnitsOf:[(self.settings)[LAUNCH_GUIDE_LENGTH_KEY] floatValue] forKey:LENGTH_UNIT_KEY];
    if (guideLength < self.launchGuideLengthStepper.minimumValue) guideLength = self.launchGuideLengthStepper.minimumValue;
    self.launchGuideLengthLabel.text = [NSString stringWithFormat:self.launchGuideLengthFormatString, guideLength];
    self.launchGuideLengthStepper.value = guideLength;
    float altitude = [SLUnitsConvertor displayUnitsOf:[(self.settings)[LAUNCH_ALTITUDE_KEY] floatValue] forKey:ALT_UNIT_KEY];
    float alt = floorf(altitude/self.siteAltitudeStepper.stepValue) * self.siteAltitudeStepper.stepValue;
    self.siteAltitudeLabel.text = [NSString stringWithFormat:@"%1.0f", alt];
    self.siteAltitudeStepper.value = alt;
    
    // disable the GPS if location services denied
    [self.GPSAltButton setEnabled:([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized
                                   || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    self.windVelocityStepper.value = [self.windVelocityLabel.text floatValue];
    float metricValue = [SLUnitsConvertor metricStandardOf:self.windVelocityStepper.value forKey:VELOCITY_UNIT_KEY];
    (self.settings)[WIND_VELOCITY_KEY] = @(metricValue);
    metricValue = [SLUnitsConvertor metricStandardOf:self.launchGuideLengthStepper.value forKey:LENGTH_UNIT_KEY];
    (self.settings)[LAUNCH_GUIDE_LENGTH_KEY] = @(metricValue);
    metricValue = [SLUnitsConvertor metricStandardOf:self.siteAltitudeStepper.value forKey:ALT_UNIT_KEY];
    (self.settings)[LAUNCH_ALTITUDE_KEY] = @(metricValue);
    [self saveSettings];
}

- (void)dealloc{
    self.locationManager = nil;
    self.settings = nil;
    self.launchGuideLengthFormatString = nil;
}

-(NSString *)description{
    return @"SimSettingsViewController";
}

@end