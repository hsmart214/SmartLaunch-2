//
//  SLSimSettingsViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/26/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import "SLSimSettingsViewController.h"
#import "SLDefinitions.h"

@interface SLSimSettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *launchAngleLabel;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityUnitsLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *windDirectionControl;
@property (weak, nonatomic) IBOutlet UISlider *windVelocitySlider;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureUnitsLabel;
@property (weak, nonatomic) IBOutlet UISlider *temperatureSlider;
@property (weak, nonatomic) IBOutlet UILabel *launchGuideLengthLabel;
@property (weak, nonatomic) IBOutlet UILabel *launchGuideLengthUnitsLabel;
@property (weak, nonatomic) IBOutlet UISlider *launchGuideLengthSlider;
@property (weak, nonatomic) IBOutlet UILabel *siteAltitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *siteAltitudeUnitsLabel;
@property (weak, nonatomic) IBOutlet UISlider *siteAltitudeSlider;

@property (strong, nonatomic) NSMutableDictionary *settings;
@property (nonatomic) float alt_step;

@end

@implementation SLSimSettingsViewController

@synthesize settings = _settings;
@synthesize launchAngleLabel = _launchAngleLabel;
@synthesize windVelocityLabel = _windVelocityLabel;
@synthesize windVelocityUnitsLabel = _windVelocityUnitsLabel;
@synthesize windDirectionControl = _windDirectionControl;
@synthesize windVelocitySlider = _windVelocitySlider;
@synthesize temperatureLabel = _temperatureLabel;
@synthesize temperatureUnitsLabel = _temperatureUnitsLabel;
@synthesize temperatureSlider = _temperatureSlider;
@synthesize launchGuideLengthLabel = _launchGuideLengthLabel;
@synthesize launchGuideLengthUnitsLabel = _launchGuideLengthUnitsLabel;
@synthesize launchGuideLengthSlider = _launchGuideLengthSlider;
@synthesize siteAltitudeLabel = _siteAltitudeLabel;
@synthesize siteAltitudeUnitsLabel = _siteAltitudeUnitsLabel;
@synthesize siteAltitudeSlider = _siteAltitudeSlider;

@synthesize delegate = _delegate;
@synthesize alt_step = _alt_step;

- (NSMutableDictionary *)settings{
    if (!_settings){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _settings = [[defaults objectForKey:SETTINGS_KEY] mutableCopy];
    }
    return _settings;
}

- (void)saveSettings{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.settings copy] forKey:SETTINGS_KEY];
    [defaults synchronize];
    [self.delegate sender:self didChangeSimSettings:self.settings withUpdate:NO];
}

- (IBAction)windDirectionChanged:(UISegmentedControl *)sender {
    NSNumber *windDir = [NSNumber numberWithInt:self.windDirectionControl.selectedSegmentIndex];
    [self.settings setObject:windDir forKey:WIND_DIRECTION_KEY];
    [self saveSettings];
}

- (IBAction)windVelocityChanged:(UISlider *)sender {
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", sender.value];
}

- (IBAction)temperatureChanged:(UISlider *)sender {
    self.temperatureLabel.text = [NSString stringWithFormat:@"%1.0f", sender.value];
}

- (IBAction)launchGuideLengthChanged:(UISlider *)sender {
    self.launchGuideLengthLabel.text = [NSString stringWithFormat:@"%1.0f", sender.value];
}

- (IBAction)siteAltitudeChanged:(UISlider *)sender {
    double alt = sender.value;
    alt = floor(alt/self.alt_step) * self.alt_step;
    self.siteAltitudeLabel.text = [NSString stringWithFormat:@"%1.0f", alt];
}

- (void)viewWillDisappear:(BOOL)animated{
    self.windVelocitySlider.value = [self.windVelocityLabel.text floatValue];
    NSNumber *metricValue = [SLUnitsConvertor metricStandardOf:[NSNumber numberWithFloat:self.windVelocitySlider.value] forKey:VELOCITY_UNIT_KEY];
    [self.settings setObject:metricValue forKey:WIND_VELOCITY_KEY];
    metricValue = [SLUnitsConvertor metricStandardOf:[NSNumber numberWithFloat:self.temperatureSlider.value] forKey:TEMP_UNIT_KEY];
    [self.settings setObject:metricValue forKey:LAUNCH_TEMPERATURE_KEY];
    metricValue = [SLUnitsConvertor metricStandardOf:[NSNumber numberWithFloat:self.launchGuideLengthSlider.value] forKey:LENGTH_UNIT_KEY];
    [self.settings setObject:metricValue forKey:LAUNCH_GUIDE_LENGTH_KEY];
    metricValue = [SLUnitsConvertor metricStandardOf:[NSNumber numberWithFloat:self.siteAltitudeSlider.value] forKey:ALT_UNIT_KEY];
    [self.settings setObject:metricValue forKey:LAUNCH_ALTITUDE_KEY];
    [self saveSettings];
}

- (void)sender:(id)sender didChangeLaunchAngle:(NSNumber *)launchAngle{
    [self.settings setObject:launchAngle forKey:LAUNCH_ANGLE_KEY];
    self.launchAngleLabel.text = [NSString stringWithFormat:@"%1.1f", [launchAngle floatValue] * DEGREES_PER_RADIAN];
    [self saveSettings];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"launchAngleSegue"]){
        [[segue destinationViewController] setTitle:@"Launch Angle"];
        [[segue destinationViewController] setDelegate:self];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    NSString *backgroundFileName = [[NSBundle mainBundle] pathForResource: BACKGROUND_IMAGE_FILENAME ofType:@"png"];
    UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:backgroundFileName];
    [backgroundView setImage:backgroundImage];
    self.tableView.backgroundView = backgroundView;
    // set up the unit labels for the preferred units
    
    self.windVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    self.temperatureUnitsLabel.text = [SLUnitsConvertor displayStringForKey:TEMP_UNIT_KEY];
    self.launchGuideLengthUnitsLabel.text = [SLUnitsConvertor displayStringForKey:LENGTH_UNIT_KEY];
    self.siteAltitudeUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *unitPrefs = [defaults objectForKey:UNIT_PREFS_KEY];
    
    if ([[unitPrefs objectForKey:ALT_UNIT_KEY] isEqualToString:K_METERS]){
        [self.siteAltitudeSlider setMaximumValue:4000];
        self.alt_step = 50;
    }else{// must be meters
        [self.siteAltitudeSlider setMaximumValue:10000];
        self.alt_step = 100;
    }
    if ([[unitPrefs objectForKey:VELOCITY_UNIT_KEY] isEqualToString:K_METER_PER_SEC]){
        [self.windVelocitySlider setMaximumValue:8.95];
    }else if ([[unitPrefs objectForKey:VELOCITY_UNIT_KEY] isEqualToString:K_FEET_PER_SEC]){
        [self.windVelocitySlider setMaximumValue:30];
    }else{// must be MPH
        [self.windVelocitySlider setMaximumValue:20];
    }
    if ([[unitPrefs objectForKey:TEMP_UNIT_KEY] isEqualToString:K_CELSIUS]){
        [self.temperatureSlider setMinimumValue:-10];
        [self.temperatureSlider setMaximumValue:42];
    }else if ([[unitPrefs objectForKey:TEMP_UNIT_KEY] isEqualToString:K_KELVINS]){
        [self.temperatureSlider setMinimumValue:260];
        [self.temperatureSlider setMaximumValue:315];
    }else{//must be Fahrenheit
        [self.temperatureSlider setMinimumValue:0];
        [self.temperatureSlider setMaximumValue:110];
    }
    if ([[unitPrefs objectForKey:LENGTH_UNIT_KEY] isEqualToString:K_FEET]){
        [self.launchGuideLengthSlider setMaximumValue:20];
    }else if ([[unitPrefs objectForKey:LENGTH_UNIT_KEY] isEqualToString:K_INCHES]){
        [self.launchGuideLengthSlider setMaximumValue:240];
    }else{//must be meters
        [self.launchGuideLengthSlider setMaximumValue:7];
    }
    
    float launchAngle = [[self.settings objectForKey:LAUNCH_ANGLE_KEY] floatValue];
    self.launchAngleLabel.text = [NSString stringWithFormat:@"%1.1f", launchAngle * DEGREES_PER_RADIAN];
    float windVelocity = [[SLUnitsConvertor displayUnitsOf: [self.settings objectForKey:WIND_VELOCITY_KEY]forKey:VELOCITY_UNIT_KEY] floatValue];
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", windVelocity];
    self.windVelocitySlider.value = windVelocity;
    float temperature = [[SLUnitsConvertor displayUnitsOf:[self.settings objectForKey:LAUNCH_TEMPERATURE_KEY] forKey:TEMP_UNIT_KEY] floatValue];
    self.temperatureLabel.text = [NSString stringWithFormat:@"%1.0f", temperature];
    self.temperatureSlider.value = temperature;
    float guideLength = [[SLUnitsConvertor displayUnitsOf:[self.settings objectForKey:LAUNCH_GUIDE_LENGTH_KEY] forKey:LENGTH_UNIT_KEY] floatValue];
    self.launchGuideLengthLabel.text = [NSString stringWithFormat:@"%1.0f", guideLength];
    self.launchGuideLengthSlider.value = guideLength;
    float altitude = [[SLUnitsConvertor displayUnitsOf:[self.settings objectForKey:LAUNCH_ALTITUDE_KEY] forKey:ALT_UNIT_KEY] floatValue];
    float alt = floorf(altitude/self.alt_step) * self.alt_step;
    self.siteAltitudeLabel.text = [NSString stringWithFormat:@"%1.0f", alt];
    self.siteAltitudeSlider.value = altitude;
}

- (void)viewDidUnload
{
    [self.delegate sender:self didChangeSimSettings:self.settings withUpdate:YES];
    [self setLaunchAngleLabel:nil];
    [self setWindVelocityLabel:nil];
    [self setWindVelocityUnitsLabel:nil];
    [self setWindDirectionControl:nil];
    [self setWindVelocitySlider:nil];
    [self setTemperatureLabel:nil];
    [self setTemperatureUnitsLabel:nil];
    [self setTemperatureSlider:nil];
    [self setLaunchGuideLengthLabel:nil];
    [self setLaunchGuideLengthUnitsLabel:nil];
    [self setLaunchGuideLengthSlider:nil];
    [self setSiteAltitudeLabel:nil];
    [self setSiteAltitudeUnitsLabel:nil];
    [self setSiteAltitudeSlider:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end