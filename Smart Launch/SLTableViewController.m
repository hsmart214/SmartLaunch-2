//
//  SLTableViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/26/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLTableViewController.h"
#import "SLPhysicsModel.h"
#import "SLDefinitions.h"
#import "SLUnitsTVC.h"
#import "SLMotorSearchViewController.h"

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

@end

@implementation SLTableViewController

@synthesize motor = _motor;
@synthesize rocket = _rocket;
@synthesize model = _model;
@synthesize settings = _settings;
@synthesize simRunning = _simRunning;
@synthesize spinner;
@synthesize thrustToWeightLabel;

@synthesize rocketCell;
@synthesize motorCell;
@synthesize windDirectionButton;
@synthesize launchAngleLabel;
@synthesize ffAngleOfAttackLabel;
@synthesize ffVelocityLabel;
@synthesize ffVelocityUnitsLabel;
@synthesize burnoutToApogeeLabel;
@synthesize apogeeAltitudeLabel;
@synthesize apogeeAltitudeUnitsLabel;

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
        _settings = [NSMutableDictionary dictionary];
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
    [self.settings setValue:launchAngle forKey:LAUNCH_ANGLE_KEY];
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
    NSString *path = [[NSBundle mainBundle] pathForResource:motor.manufacturer ofType:@"jpg"];
    UIImage *theImage = [UIImage imageWithContentsOfFile:path];
    self.motorCell.imageView.image = theImage;
    if (self.view.window)[self updateDisplay];
}

- (void)sender:(id)sender didChangeSimSettings:(NSDictionary *)settings withUpdate:(BOOL)update{
    self.settings = [settings mutableCopy];
    [self defaultStoreWithKey:SETTINGS_KEY andValue:self.settings];
    if (update){
        [self updateDisplay];
    }
}

#pragma mark - Smart Launch

- (IBAction)windDirectionDidChange:(UIButton *)sender {
    if (self.simRunning) return; // this is to keep from showing sim results not consistent with sim settings
    // otherwise you could change wind direction in the middle of a sim run, but the sim would not run again to account for the change
    
    NSArray *buttonNames = [NSArray arrayWithObjects:
                            @"With Wind",
                            @"CrossWind",
                            @"Into Wind", nil];
    NSInteger dir;
    for (dir = 0; dir < 3; dir++) {
        if ([sender.currentTitle isEqualToString:[buttonNames objectAtIndex:dir]]){
            break;
        }
    }
    dir = (dir + 1) % 3;
    [sender setTitle:[buttonNames objectAtIndex:dir] forState:UIControlStateNormal];
    [self.settings setObject:[NSNumber numberWithInt:dir] forKey:WIND_DIRECTION_KEY];
    [self updateDisplay];
}

- (void)updateDisplay{
    self.thrustToWeightLabel.text = [NSString stringWithFormat:@"%1.1f : 1", ([[self.motor peakThrust] floatValue])/(([self.rocket.mass floatValue] + [self.motor.loadedMass floatValue])*(GRAV_ACCEL))];
    self.rocketCell.textLabel.text = self.rocket.name;
    self.rocketCell.detailTextLabel.text = [NSString stringWithFormat:@"%dmm", [self.rocket.motorSize intValue]];
    self.motorCell.textLabel.text = self.motor.name;
    self.motorCell.detailTextLabel.text =[NSString stringWithFormat:@"%1.1f Ns", [self.motor.totalImpulse floatValue]];
    NSString *path = [[NSBundle mainBundle] pathForResource:self.motor.manufacturer ofType:@"png"];
    UIImage *theImage = [UIImage imageWithContentsOfFile:path];
    self.motorCell.imageView.image = theImage;
    
    // In the following I let the SLUnitsConvertor class do all of the unit changing.  This controller is not even aware of the UNIT_PREFS settings

    self.launchAngleLabel.text = [NSString stringWithFormat:@"%1.1f",[[self.settings objectForKey:LAUNCH_ANGLE_KEY] floatValue] * DEGREES_PER_RADIAN];
    NSArray *buttonNames = [NSArray arrayWithObjects:
                            @"With Wind",
                            @"CrossWind",
                            @"Into Wind", nil];
    [self.windDirectionButton setTitle:[buttonNames objectAtIndex:[[self.settings objectForKey:WIND_DIRECTION_KEY] intValue]] forState:UIControlStateNormal];
    self.ffVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    self.apogeeAltitudeUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    if (self.view.window && !self.simRunning){
        self.simRunning = YES;
        [self.spinner startAnimating];
        dispatch_queue_t queue = dispatch_queue_create("simQueue", NULL);
        dispatch_async(queue, ^{
            self.model.motor = self.motor;
            self.model.rocket = self.rocket;
            self.model.launchGuideAngle = [[self.settings objectForKey:LAUNCH_ANGLE_KEY] floatValue];
            float len = [[self.settings objectForKey:LAUNCH_GUIDE_LENGTH_KEY] floatValue];
            if (len == 0) len = 1.0;
            self.model.launchGuideLength = len;
            self.model.windVelocity = [[self.settings objectForKey:WIND_VELOCITY_KEY] floatValue];
            self.model.LaunchGuideDirection = (enum LaunchDirection)[[self.settings objectForKey:WIND_DIRECTION_KEY] intValue];
            self.model.launchAltitude = [[self.settings objectForKey:LAUNCH_ALTITUDE_KEY] floatValue];
            [self.model resetFlight];
            
            // run the sim in metric units
            float aoaRadians = [self.model freeFlightAngleOfAttack];
            float aoa = aoaRadians * DEGREES_PER_RADIAN;
            double ffVelocity = [self.model velocityAtEndOfLaunchGuide];
            double apogee = [self.model apogee];
            double coastTime = [self.model burnoutToApogee]; //+ 0.5;  when I truncate this, it will be rounded
            
            // convert the two results that might be in different units
            
            double velocityInPreferredUnits = [[SLUnitsConvertor displayUnitsOf:[NSNumber numberWithDouble:ffVelocity] forKey:VELOCITY_UNIT_KEY] doubleValue];
            double apogeeInPreferredUnits = [[SLUnitsConvertor displayUnitsOf:[NSNumber numberWithDouble:apogee] forKey:ALT_UNIT_KEY] doubleValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                // display the result, all in user-defined units
                self.ffAngleOfAttackLabel.text = [NSString stringWithFormat:@"%1.1f", aoa];
                self.ffVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", velocityInPreferredUnits];
                self.apogeeAltitudeLabel.text = [NSString stringWithFormat:@"%1.0f", apogeeInPreferredUnits];
                self.burnoutToApogeeLabel.text = [NSString stringWithFormat:@"%1.1f", coastTime];
                self.simRunning = NO;
                [self.spinner stopAnimating];
            });
        });
        dispatch_release(queue);
    }
}

#pragma mark - SLSimulationDataSource methods

- (NSMutableDictionary *)simulationSettings{
    return [self.settings mutableCopy];
}

- (NSNumber *)freeFlightVelocity{
    return [NSNumber numberWithDouble:[self.model velocityAtEndOfLaunchGuide]];
}

- (NSNumber *)freeFlightAoA{
    return [NSNumber numberWithFloat:[self.model freeFlightAngleOfAttack]];
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

- (enum LaunchDirection)launchGuideDirection{
    return [self.settings[WIND_DIRECTION_KEY] integerValue];
}

- (float)quickFFVelocityAtAngle:(float)angle andGuideLength:(float)length{
    return [self.model quickFFVelocityAtLaunchAngle:angle andGuideLength:length];
}

- (void)dismissModalViewController{
    [self.presentedViewController dismissModalViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [segue.destinationViewController setDelegate:self];
    if ([[segue identifier] isEqualToString:@"settingsModalSegue"]){
        [[[(UINavigationController *)segue.destinationViewController viewControllers] objectAtIndex:0] setDelegate:self];
    }
    if ([[segue identifier] isEqualToString:@"motorSelectorSegue"]){
        // this is part of the model for this destination VC, so we can set this
        [(SLMotorSearchViewController *)segue.destinationViewController setRocketMotorMountDiameter:self.rocket.motorSize];
    }
    if ([[segue identifier] isEqualToString:@"AnimationSegue"]){
        [segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setDataSource:self];
    }
}


#pragma mark - View Life Cycle

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self updateDisplay];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    NSString *backgroundFileName = [[NSBundle mainBundle] pathForResource: BACKGROUND_IMAGE_FILENAME ofType:@"png"];
    UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:backgroundFileName];
    [backgroundView setImage:backgroundImage];
    self.tableView.backgroundView = backgroundView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
