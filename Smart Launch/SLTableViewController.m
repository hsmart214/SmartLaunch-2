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
#import "SLClusterMotorBuildViewController.h"
#import "SLRocketPropertiesTVC.h"
#import "SLClusterMotorViewController.h"

#define FLIGHT_PROFILE_ROW 5
#define MOTOR_SELECTION_ROW 1

@interface SLTableViewController ()<SLMotorPickerDatasource, SLRocketPropertiesTVCDelegate>
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
@property (weak, nonatomic) IBOutlet UIImageView *manufacturerLogoView;
@property (weak, nonatomic) IBOutlet UILabel *motorDetailDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorNameLabel;

@property (strong, nonatomic) Rocket *rocket;
@property (strong, nonatomic) SLPhysicsModel *model;
@property (strong, nonatomic) NSMutableDictionary *settings;
@property (atomic) BOOL simRunning;
@property (nonatomic, strong) id iCloudObserver;
@property (nonatomic, weak) UIPopoverController *popover;

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
                     [self.rocket rocketPropertyList], SELECTED_ROCKET_KEY,
                     [self.rocket motorLoadoutPlist], SELECTED_MOTOR_KEY,
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
    self.rocketCell.detailTextLabel.text = [rocket.manufacturer description];
    NSArray *motorPlist = [self.rocket motorLoadoutPlist];
    [self.settings setValue:motorPlist forKey:SELECTED_MOTOR_KEY];
    [self defaultStoreWithKey:SELECTED_MOTOR_KEY andValue:motorPlist];
    if ([motorPlist count]) self.motorNameLabel.text = motorPlist[0][MOTOR_PLIST_KEY][NAME_KEY];
    self.motorDetailDescriptionLabel.text = [NSString stringWithFormat:@"%1.1f N-sec", [self.rocket totalImpulse]];
    if (self.rocket.motorManufacturer) self.manufacturerLogoView.image  = [UIImage imageNamed:self.rocket.motorManufacturer];
    
    // update the "last used" motor in the rocket list and in the cloud
    [self SLRocketPropertiesTVC:(id)self savedRocket:self.rocket];
    
    if (self.view.window)[self updateDisplay];
}

- (void)sender:(id)sender didChangeRocketMotor:(NSArray *)motorPlist{
    [self.rocket replaceMotorLoadOutWithLoadOut:motorPlist];
    [self sender:self didChangeRocket:self.rocket];
}

- (void)sender:(id)sender didChangeSimSettings:(NSDictionary *)settings withUpdate:(BOOL)shouldUpdate{
    self.settings = [settings mutableCopy];
    [self defaultStoreWithKey:SETTINGS_KEY andValue:self.settings];
    if (shouldUpdate){
        [self updateDisplay];
    }
}

-(void)didChangeUnitPrefs:(id)sender{
    if (self.splitViewController){
        UINavigationController *nav = (UINavigationController *)[self.splitViewController.viewControllers lastObject];
        [(SLiPadDetailViewController *)nav.viewControllers[0] updateDisplay];
    }
}

-(BOOL)shouldAllowSimulationUpdates{
    return !self.simRunning;
}

- (void)dismissModalViewController{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    [self.popover dismissPopoverAnimated:YES];
}

#pragma mark - SLRocketPropertiesTVCDelegate

- (void)SLRocketPropertiesTVC:(SLRocketPropertiesTVC *)sender savedRocket:(Rocket *)rocket{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSMutableDictionary *rocketFavorites = [[defaults objectForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
    if (!rocketFavorites) rocketFavorites = [NSMutableDictionary dictionary];
    rocketFavorites[rocket.name] = [rocket rocketPropertyList];
    [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    [store setDictionary:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    [defaults synchronize];
    self.rocket = rocket;
}

- (void)SLRocketPropertiesTVC:(SLRocketPropertiesTVC *)sender deletedRocket:(Rocket *)rocket{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSMutableDictionary *rocketFavorites = [[defaults objectForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
    if (!rocketFavorites||[rocketFavorites count]==0) return;
    [rocketFavorites removeObjectForKey:rocket.name];
    [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    [store setDictionary:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    [defaults synchronize];
}

#pragma mark - Smart Launch

- (IBAction)windDirectionDidChange:(UIButton *)sender {
    if (self.simRunning) return; // this is to keep from showing sim results not consistent with sim settings
    // otherwise you could change wind direction in the middle of a sim run, but the sim would not run again to account for the change
    
    NSArray *buttonNames = @[NSLocalizedString(@"With Wind", @"With Wind") ,
                            NSLocalizedString(@"CrossWind", @"CrossWind"),
                            NSLocalizedString(@"Into Wind", @"Into Wind")];
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
    self.thrustToWeightLabel.text = [NSString stringWithFormat:@"%1.1f : 1", ([self.rocket peakThrust])/(([self.rocket massAtTime:0.0])*(GRAV_ACCEL))];
    self.rocketCell.textLabel.text = self.rocket.name;
    self.rocketCell.detailTextLabel.text = [NSString stringWithFormat:@"%dmm", self.rocket.motorSize];
    self.motorNameLabel.text = [self.rocket motorDescription];
    SLClusterMotor *cMotor = [[SLClusterMotor alloc] initWithMotorLoadout:self.rocket.motorLoadoutPlist];
    self.motorDetailDescriptionLabel.text = [cMotor fractionalImpulseClass];
    //    self.motorDetailDescriptionLabel.text =[NSString stringWithFormat:@"%1.1f Ns", [self.rocket totalImpulse]];
    UIImage *theImage;
    
    // This should protect against the Catalog errors about no image present
    if (self.rocket.motorManufacturer){
        theImage = [UIImage imageNamed:self.rocket.motorManufacturer];
    }else{
        theImage = nil;
    }
    
    self.manufacturerLogoView.image = theImage;
    
    // In the following I let the SLUnitsConvertor class do all of the unit changing.  This controller is not even aware of the UNIT_PREFS settings

    self.launchAngleLabel.text = [NSString stringWithFormat:@"%1.1f",[(self.settings)[LAUNCH_ANGLE_KEY] floatValue] * DEGREES_PER_RADIAN];
    NSArray *buttonNames = @[NSLocalizedString(@"With Wind", @"With Wind") ,
                             NSLocalizedString(@"CrossWind", @"CrossWind"),
                             NSLocalizedString(@"Into Wind", @"Into Wind")];
    [self.windDirectionButton setTitle:buttonNames[[(self.settings)[WIND_DIRECTION_KEY] intValue]] forState:UIControlStateNormal];
    self.ffVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    self.apogeeAltitudeUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    if ((self.view.window || self.splitViewController) && !self.simRunning){    // always run sim if we are on an iPad, unless it is already running
        self.simRunning = YES;
        [self.spinner startAnimating];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.model.rocket = self.rocket;
            self.model.launchGuideAngle = [(self.settings)[LAUNCH_ANGLE_KEY] floatValue];
            float len = [(self.settings)[LAUNCH_GUIDE_LENGTH_KEY] floatValue];
            if (len == 0) len = 1.0;  // defend against zero-divide errors
            self.model.launchGuideLength = len;
            self.model.windVelocity = [(self.settings)[WIND_VELOCITY_KEY] floatValue];
            self.model.LaunchGuideDirection = (LaunchDirection)[(self.settings)[WIND_DIRECTION_KEY] intValue];
            self.model.launchAltitude = [(self.settings)[LAUNCH_ALTITUDE_KEY] floatValue];
            [self.model resetFlight];
            
            // run the sim in metric units
            float aoaRadians = [self.model freeFlightAngleOfAttack];
            float aoa = aoaRadians * DEGREES_PER_RADIAN;
            double ffVelocity = [self.model velocityAtEndOfLaunchGuide];
            double apogee = [self.model apogee];
            double coastTime = [self.model burnoutToApogee]; //+ 0.5;  when I truncate this, it will be rounded
            
            // convert the two results that might be in different units
            
            float velocityInPreferredUnits = [SLUnitsConvertor displayUnitsOf:ffVelocity forKey:VELOCITY_UNIT_KEY];
            float apogeeInPreferredUnits = [SLUnitsConvertor displayUnitsOf:apogee forKey:ALT_UNIT_KEY];
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

#pragma mark - SLMotorPickerDatasource method

-(NSUInteger)motorSizeRequested{
    // if there is more than one, this will return the first one, which should be the central one
    return self.rocket.motorSize;
}

#pragma mark - SLSimulationDataSource methods

- (NSMutableDictionary *)simulationSettings{
    return [self.settings mutableCopy];
}

- (float)freeFlightVelocity{
    return [self.model velocityAtEndOfLaunchGuide];
}

- (float)freeFlightAoA{
    return [self.model freeFlightAngleOfAttack];
}

- (float)windVelocity{
    return [self.settings[WIND_VELOCITY_KEY] floatValue];
}

- (float)launchAngle{
    return [self.settings[LAUNCH_ANGLE_KEY] floatValue];
}

- (float)launchGuideLength{
    float length = [self.settings[LAUNCH_GUIDE_LENGTH_KEY] floatValue];
    if (length < MIN_LAUNCH_GUIDE_LENGTH) length = MIN_LAUNCH_GUIDE_LENGTH;
    return length;
}

-(float)launchSiteAltitude{
    return [self.settings[LAUNCH_ALTITUDE_KEY] floatValue];
}

- (LaunchDirection)launchGuideDirection{
    return [self.settings[WIND_DIRECTION_KEY] integerValue];
}

- (float)quickFFVelocityAtAngle:(float)angle andGuideLength:(float)length{
    return [self.model quickFFVelocityAtLaunchAngle:angle andGuideLength:length];
}

#pragma mark - Prepare For Segue

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
        [(SLMotorSearchViewController *)segue.destinationViewController setDataSource:self];
        [(SLMotorSearchViewController *)segue.destinationViewController setPopBackController:self];
    }
    if ([[segue identifier] isEqualToString:@"AnimationSegue"]){
        [segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setDataSource:self];
    }
    if ([[segue identifier] isEqualToString:@"saveFlightSegue"]){
        NSMutableDictionary *flightSettings = [self.settings mutableCopy];
        [flightSettings removeObjectForKey:SELECTED_ROCKET_KEY];
        if (self.settings[SELECTED_MOTOR_KEY]) flightSettings[SELECTED_ROCKET_KEY] = self.settings[SELECTED_MOTOR_KEY];
  
        NSDictionary *flight = @{MOTOR_PLIST_KEY : [self.rocket motorLoadoutPlist] ,
                                 FLIGHT_MOTOR_LONGNAME_KEY : [NSString stringWithFormat:@"%@ %@", self.rocket.motorManufacturer, self.rocket.motorDescription],
                                 FLIGHT_BEST_CD : @(self.rocket.cd),
                                 FLIGHT_ALTITUDE_KEY : @([SLUnitsConvertor metricStandardOf:[self.apogeeAltitudeLabel.text floatValue] forKey:ALT_UNIT_KEY]),
                                 FLIGHT_SETTINGS_KEY: flightSettings,
                                 SMART_LAUNCH_VERSION_KEY: @(SMART_LAUNCH_VERSION)};
        SLSaveFlightDataTVC *dest;
        if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]){
            dest = (SLSaveFlightDataTVC *)([segue.destinationViewController viewControllers][0]);
        }else{
            dest = (SLSaveFlightDataTVC *)segue.destinationViewController;
            self.popover = ((UIStoryboardPopoverSegue *)segue).popoverController;
        }
        [dest setFlightData:flight];
        [dest setPhysicsModel:self.model];
        [dest setRocket:self.rocket];
        [dest setDelegate:self];
    }
    if ([[segue identifier] isEqualToString:@"FlightProfileSegue"]){
        [(SLFlightProfileViewController *)segue.destinationViewController setDataSource:self.model];
    }
    if ([[segue identifier] isEqualToString:@"clusterBuildSegue"]){
        [(SLClusterMotorBuildViewController *)segue.destinationViewController setSimDelegate:self];
        [(SLClusterMotorBuildViewController *)segue.destinationViewController setSimDatasource:self];
        [(SLClusterMotorBuildViewController *)segue.destinationViewController setMotorConfiguration:self.rocket.motorConfig];
        [(SLClusterMotorBuildViewController *)segue.destinationViewController setMotorLoadoutPlist:[self.rocket motorLoadoutPlist]];
        [(SLClusterMotorBuildViewController *)segue.destinationViewController setSavedMotorLoadoutPlists:[self.rocket previousLoadOuts]];
    }
    if ([segue.identifier isEqualToString:@"RocketDirectEditSegue"]){
        [(SLRocketPropertiesTVC *)segue.destinationViewController setRocket:self.rocket];
        [(SLRocketPropertiesTVC *)segue.destinationViewController setTitle:self.rocket.name];
        [(SLRocketPropertiesTVC *)segue.destinationViewController setDelegate:self];
    }
    if ([segue.identifier isEqualToString:@"ClusterThrustViewSegue"]){
        [(SLClusterMotorViewController *)segue.destinationViewController setMotorLoadoutPlist:self.rocket.motorLoadoutPlist];
        [(SLClusterMotorViewController *)segue.destinationViewController setDelegate:self];
        [(SLClusterMotorViewController *)segue.destinationViewController setPopBackViewController:self];
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
    if (indexPath.section == 0 && indexPath.row == MOTOR_SELECTION_ROW){
        if ([self.rocket hasClusterMount]){
            [self performSegueWithIdentifier:@"clusterBuildSegue" sender:self];
        }else{
            [self performSegueWithIdentifier:@"motorSelectorSegue" sender:self];
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) return 0.0;
    return [SLCustomUI headerHeight];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section == 0) return nil;
    NSString *headerText;
    if (section == 1){
        headerText = NSLocalizedString(@"Simulation Results", @"Simulation Results (header)");
    }else{  // must be last section - there are only three
        headerText = NSLocalizedString(@"Smart Launch", @"Smart Launch (header)");
    }
    UILabel *headerLabel = [[UILabel alloc] init];
    [headerLabel setTextColor:[SLCustomUI headerTextColor]];
    [headerLabel setBackgroundColor:self.tableView.backgroundColor];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setText:headerText];
    [headerLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
    
    
    return headerLabel;
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0){
        [self performSegueWithIdentifier:@"RocketDirectEditSegue" sender:self];
    }
    if (indexPath.row == 1){
        if ([self.rocket.motors count] == 0) return;
        [self performSegueWithIdentifier:@"ClusterThrustViewSegue" sender:self];
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
        self.tableView.backgroundColor = [UIColor clearColor];
    }else{// we are on an iPad
        //self.tableView.backgroundColor = [SLCustomUI iPadBackgroundColor];
        //trying out the same bacjground for both systems
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_FOR_IPAD_MASTER_VC];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
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

-(NSString *)description{
    return @"Smart Launch HD TVC";
}

@end
