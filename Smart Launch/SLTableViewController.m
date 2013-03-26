//
//  SLTableViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/26/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLTableViewController.h"
#import "SLPhysicsModel.h"
#import "SLUnitsTVC.h"
#import "SLMotorSearchViewController.h"
#import "SLSaveFlightDataTVC.h"
#import "SLFlightProfileViewController.h"
#import "SLUnitsConvertor.h"
#import "SLiPadDetailViewController.h"

#define FLIGHT_PROFILE_ROW 5

@interface SLTableViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *rocketCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *motorCell;
@property (weak, nonatomic) IBOutlet UIButton *windDirectionButton;
@property (weak, nonatomic) IBOutlet UILabel *launchAngleLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffAngleOfAttackLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffVelocityUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *burnoutToApogeeLabel;
@property (weak, nonatomic) IBOutlet UILabel *apogeeAltitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *apogeeAltitudeUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *thrustToWeightLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) Rocket *rocket;
@property (strong, nonatomic) RocketMotor *motor;
@property (strong, nonatomic) SLPhysicsModel *model;
@property (strong, nonatomic) NSMutableDictionary *settings;
@property (atomic) BOOL simRunning;
@property (nonatomic, strong) id iCloudObserver;

@end

@implementation SLTableViewController

- (Rocket *)rocket{
    if (!_rocket){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *rocketDict = [defaults objectForKey:SELECTED_ROCKET_KEY];
        if (rocketDict){
            _rocket = [Rocket rocketWithRocketDict:rocketDict];
        }else{
            // no selected rocket.  this will only happen on the first launch
            _rocket = [Rocket defaultRocket];
            [defaults setObject:[_rocket rocketPropertyList] forKey:SELECTED_ROCKET_KEY];
            [defaults synchronize];
        }
    }
    return _rocket;
}

- (RocketMotor *)motor{
    if (!_motor){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *motorDict = [defaults objectForKey:SELECTED_MOTOR_KEY];
        if (motorDict){
            _motor = [RocketMotor motorWithMotorDict:motorDict];
        }else{
            // no selected motor.  this should only happen on the first start-up
            _motor = [RocketMotor defaultMotor];
            [defaults setObject:[_motor motorDict] forKey:SELECTED_MOTOR_KEY];
            [defaults synchronize];
        }
    }
    return _motor;
}

- (void)defaultStoreWithKey:(NSString *)key
                   andValue:(id)value{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

- (id)defaultFetchWithKey:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults objectForKey:key] mutableCopy];
}

- (NSMutableDictionary *)settings{
    if (!_settings){
        _settings = [self defaultFetchWithKey:SETTINGS_KEY];
    }
    if (!_settings){    // This can only happen on the very first run of the program
                        // We will put some sensible settings in to avoid problems with nil values
        _settings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                     @0.9, WIND_VELOCITY_KEY,             //2 MPH
                     @0.9144, LAUNCH_GUIDE_LENGTH_KEY,    //36 inches
                     @0.0, LAUNCH_ANGLE_KEY,
                     @33.0, LAUNCH_ALTITUDE_KEY,          //100 feet
                     nil];
        [self defaultStoreWithKey:SETTINGS_KEY andValue:_settings];
        // If this is the first run we also need to set the standard defaults
        [SLUnitsTVC setStandardDefaults];
    }
    return _settings;
}

- (SLPhysicsModel *)model{
    if (!_model){
        _model = [[SLPhysicsModel alloc] init];
    }
    return _model;
}

#pragma mark - Sim delegate methods

- (void)sender:(id)sender didChangeLaunchAngle:(NSNumber *)launchAngle{  // launch angle in radians
    self.settings[LAUNCH_ANGLE_KEY] = launchAngle;
    [self defaultStoreWithKey:SETTINGS_KEY andValue:self.settings];
    self.launchAngleLabel.text = [NSString stringWithFormat:@"%1.1f", [launchAngle floatValue] * DEGREES_PER_RADIAN];
    if (self.view.window)[self updateDisplay];
}

- (void)sender:(id)sender didChangeRocket:(Rocket *)rocket{
    self.rocket = rocket;
    [self.settings setValue:[rocket rocketPropertyList] forKey:SELECTED_ROCKET_KEY];
    [self defaultStoreWithKey:SELECTED_ROCKET_KEY andValue:[rocket rocketPropertyList]];
    [self defaultStoreWithKey:SETTINGS_KEY andValue:self.settings];
    self.rocketCell.textLabel.text = rocket.name;
    self.rocketCell.detailTextLabel.text = [NSString stringWithFormat:@"%dmm", [rocket.motorSize intValue]];
    if (self.view.window)[self updateDisplay];
}

- (void)sender:(id)sender didChangeRocketMotor:(RocketMotor *)motor{
    self.motor = motor;
    [self.settings setValue:[motor motorDict] forKey:SELECTED_MOTOR_KEY];
    [self defaultStoreWithKey:SELECTED_MOTOR_KEY andValue:[motor motorDict]];
    [self defaultStoreWithKey:SETTINGS_KEY andValue:self.settings];
    self.motorCell.textLabel.text = motor.name;
    self.motorCell.detailTextLabel.text = [NSString stringWithFormat:@"%1.1f", [motor.totalImpulse floatValue]];
    UIImage *theImage = [UIImage imageNamed:motor.manufacturer];
    self.motorCell.imageView.image = theImage;
    if (self.view.window)[self updateDisplay];
}

- (void)sender:(id)sender didChangeSimSettings:(NSDictionary *)settings withUpdate:(BOOL)shouldUpdate{
    self.settings = [settings mutableCopy];
    [self defaultStoreWithKey:SETTINGS_KEY andValue:self.settings];
    if (shouldUpdate){
        [self updateDisplay];
    }
}

#pragma mark - Smart Launch

- (IBAction)windDirectionDidChange:(UIButton *)sender {
    if (self.simRunning) return; // this is to keep from showing sim results not consistent with sim settings
    // otherwise you could change wind direction in the middle of a sim run, but the sim would not run again to account for the change
    
    NSArray *buttonNames = @[@"With Wind",
                            @"CrossWind",
                            @"Into Wind"];
    NSInteger dir;
    for (dir = 0; dir < 3; dir++) {
        if ([sender.currentTitle isEqualToString:buttonNames[dir]]){
            break;
        }
    }
    dir = (dir + 1) % 3;
    [sender setTitle:buttonNames[dir] forState:UIControlStateNormal];
    (self.settings)[WIND_DIRECTION_KEY] = @(dir);
    [self updateDisplay];
}

- (void)updateDisplay{
    self.thrustToWeightLabel.text = [NSString stringWithFormat:@"%1.1f : 1", ([[self.motor peakThrust] floatValue])/(([self.rocket.mass floatValue] + [self.motor.loadedMass floatValue])*(GRAV_ACCEL))];
    self.rocketCell.textLabel.text = self.rocket.name;
    self.rocketCell.detailTextLabel.text = [NSString stringWithFormat:@"%dmm", [self.rocket.motorSize intValue]];
    self.motorCell.textLabel.text = self.motor.name;
    self.motorCell.detailTextLabel.text =[NSString stringWithFormat:@"%1.1f Ns", [self.motor.totalImpulse floatValue]];
    UIImage *theImage = [UIImage imageNamed:self.motor.manufacturer];
    self.motorCell.imageView.image = theImage;
    
    // In the following I let the SLUnitsConvertor class do all of the unit changing.  This controller is not even aware of the UNIT_PREFS settings

    self.launchAngleLabel.text = [NSString stringWithFormat:@"%1.1f",[(self.settings)[LAUNCH_ANGLE_KEY] floatValue] * DEGREES_PER_RADIAN];
    NSArray *buttonNames = @[@"With Wind",
                            @"CrossWind",
                            @"Into Wind"];
    [self.windDirectionButton setTitle:buttonNames[[(self.settings)[WIND_DIRECTION_KEY] intValue]] forState:UIControlStateNormal];
    self.ffVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    self.apogeeAltitudeUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    if ((self.view.window || self.splitViewController) && !self.simRunning){    // always run sim if we are on an iPad, unless it is already running
        self.simRunning = YES;
        [self.spinner startAnimating];
        dispatch_queue_t queue = dispatch_queue_create("simQueue", NULL);
        dispatch_async(queue, ^{
            self.model.motor = self.motor;
            self.model.rocket = self.rocket;
            self.model.launchGuideAngle = [(self.settings)[LAUNCH_ANGLE_KEY] floatValue];
            float len = [(self.settings)[LAUNCH_GUIDE_LENGTH_KEY] floatValue];
            if (len == 0) len = 1.0;  // defend against zero-divide errors
            self.model.launchGuideLength = len;
            self.model.windVelocity = [(self.settings)[WIND_VELOCITY_KEY] floatValue];
            self.model.LaunchGuideDirection = (enum LaunchDirection)[(self.settings)[WIND_DIRECTION_KEY] intValue];
            self.model.launchAltitude = [(self.settings)[LAUNCH_ALTITUDE_KEY] floatValue];
            [self.model resetFlight];
            
            // run the sim in metric units
            float aoaRadians = [self.model freeFlightAngleOfAttack];
            float aoa = aoaRadians * DEGREES_PER_RADIAN;
            double ffVelocity = [self.model velocityAtEndOfLaunchGuide];
            double apogee = [self.model apogee];
            double coastTime = [self.model burnoutToApogee]; //+ 0.5;  when I truncate this, it will be rounded
            
            // convert the two results that might be in different units
            
            double velocityInPreferredUnits = [[SLUnitsConvertor displayUnitsOf:@(ffVelocity) forKey:VELOCITY_UNIT_KEY] doubleValue];
            double apogeeInPreferredUnits = [[SLUnitsConvertor displayUnitsOf:@(apogee) forKey:ALT_UNIT_KEY] doubleValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                // display the result, all in user-defined units
                self.ffAngleOfAttackLabel.text = [NSString stringWithFormat:@"%1.1f", aoa];
                self.ffVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", velocityInPreferredUnits];
                self.apogeeAltitudeLabel.text = [NSString stringWithFormat:@"%1.0f", apogeeInPreferredUnits];
                self.burnoutToApogeeLabel.text = [NSString stringWithFormat:@"%1.1f", coastTime];
                self.simRunning = NO;
                [self.spinner stopAnimating];
                if (self.splitViewController){
                    UINavigationController *nav = (UINavigationController *)[self.splitViewController.viewControllers lastObject];
                    [(SLiPadDetailViewController *)nav.viewControllers[0] updateDisplay];
                }
            });
        });
    }
}

#pragma mark - SLSimulationDataSource methods

- (NSMutableDictionary *)simulationSettings{
    return [self.settings mutableCopy];
}

- (NSNumber *)freeFlightVelocity{
    return @([self.model velocityAtEndOfLaunchGuide]);
}

- (NSNumber *)freeFlightAoA{
    return @([self.model freeFlightAngleOfAttack]);
}

- (NSNumber *)windVelocity{
    return self.settings[WIND_VELOCITY_KEY];
}

- (NSNumber *)launchAngle{
    return self.settings[LAUNCH_ANGLE_KEY];
}

- (NSNumber *)launchGuideLength{
    return self.settings[LAUNCH_GUIDE_LENGTH_KEY];
}

-(NSNumber *)launchSiteAltitude{
    return self.settings[LAUNCH_ALTITUDE_KEY];
}

- (enum LaunchDirection)launchGuideDirection{
    return [self.settings[WIND_DIRECTION_KEY] integerValue];
}

- (float)quickFFVelocityAtAngle:(float)angle andGuideLength:(float)length{
    return [self.model quickFFVelocityAtLaunchAngle:angle andGuideLength:length];
}

- (void)dismissModalViewController{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [segue.destinationViewController setDelegate:self];
    if ([[segue identifier] isEqualToString:@"settingsModalSegue"]){
        [[(UINavigationController *)segue.destinationViewController viewControllers][0] setDelegate:self];
    }
    if ([[segue identifier] isEqualToString:@"settingsPushSegue"]){
        [segue.destinationViewController setDelegate:self];
    }
    if ([[segue identifier] isEqualToString:@"motorSelectorSegue"]){
        // this is part of the model for this destination VC, so we can set this
        [(SLMotorSearchViewController *)segue.destinationViewController setRocketMotorMountDiameter:self.rocket.motorSize];
    }
    if ([[segue identifier] isEqualToString:@"AnimationSegue"]){
        [segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setDataSource:self];
    }
    if ([[segue identifier] isEqualToString:@"saveFlightSegue"]){
        NSDictionary *flight = @{FLIGHT_MOTOR_KEY : self.motor.name,
                                 FLIGHT_MOTOR_LONGNAME_KEY : [NSString stringWithFormat:@"%@ %@", self.motor.manufacturer, self.motor.name],
                                 FLIGHT_BEST_CD : self.rocket.cd,
                                 FLIGHT_ALTITUDE_KEY : [SLUnitsConvertor metricStandardOf:@([self.apogeeAltitudeLabel.text floatValue]) forKey:ALT_UNIT_KEY],
                                 FLIGHT_SETTINGS_KEY: self.settings};
        [(SLSaveFlightDataTVC *)segue.destinationViewController setFlightData:flight];
        [(SLSaveFlightDataTVC *)segue.destinationViewController setPhysicsModel:self.model];
        [(SLSaveFlightDataTVC *)segue.destinationViewController setRocket:self.rocket];
    }
    if ([[segue identifier] isEqualToString:@"FlightProfileSegue"]){
        [(SLFlightProfileViewController *)segue.destinationViewController setDataSource:self.model];
    }
}

#pragma mark - TableView dataSource Methods

// This clumsy bit is necessary to keep from choosing the flight profile while the
// profile is still being calculated.  Crashola!

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == FLIGHT_PROFILE_ROW){
        if (self.simRunning){
            return;
        }else{
            [self performSegueWithIdentifier:@"FlightProfileSegue" sender:self];
        }
    }
}

#pragma mark - View Life Cycle

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
    if (!self.iCloudObserver){
        self.iCloudObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil queue:nil usingBlock:^(NSNotification *notification){
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
            NSArray *changedKeys = [[notification userInfo] objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
            for (NSString *key in changedKeys) {
                [defaults setObject:[store objectForKey:key] forKey:key];       // right now this can only be the favorite rockets dictionary
            }
            [defaults synchronize];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self updateDisplay];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self.iCloudObserver];
    self.iCloudObserver = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    id unitPrefs = [self defaultFetchWithKey:UNIT_PREFS_KEY];
    if (!unitPrefs) [SLUnitsTVC setStandardDefaults];
    
    if (!self.splitViewController){
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
    }
    self.iCloudObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil queue:nil usingBlock:^(NSNotification *notification){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *changedKeys = [[notification userInfo] objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        for (NSString *key in changedKeys) {
            [defaults setObject:[store objectForKey:key] forKey:key];       // right now this can only be the favorite rockets dictionary
        }
        [defaults synchronize];
    }];
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    if (self.splitViewController){
        UINavigationController *nav = (UINavigationController *)[self.splitViewController.viewControllers lastObject];
        [(SLiPadDetailViewController *)nav.viewControllers[0] setModel:self.model];
        [(SLiPadDetailViewController *)nav.viewControllers[0] setSimDelegate:self];
        [(SLiPadDetailViewController *)nav.viewControllers[0] setSimDataSource:self];
    }
}
@end
