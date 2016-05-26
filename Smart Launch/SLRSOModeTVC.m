//
//  SLRSOModeTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 5/26/16.
//  Copyright © 2016 J. HOWARD SMART. All rights reserved.
//

#import "SLRSOModeTVC.h"
#import "SLUnitsConvertor.h"
#import "SLMotorSearchViewController.h"
#import "SLAnimatedViewController.h"
#import "SLClusterMotorViewController.h"

@interface SLRSOModeTVC ()<SLSimulationDelegate, SLSimulationDataSource>

@property (strong, nonatomic) Rocket *rocket;
@property (strong, nonatomic) SLPhysicsModel *model;
@property (strong, nonatomic) RocketMotor *motor;

@property (weak, nonatomic) IBOutlet UILabel *diamLabel;
@property (weak, nonatomic) IBOutlet UILabel *liftMassLabel;
@property (weak, nonatomic) IBOutlet UIImageView *motorManufacturerLogoImageView;
@property (weak, nonatomic) IBOutlet UILabel *motorShortNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorTotalImpulseLabel;

@end

@implementation SLRSOModeTVC

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    // there is only one
    [self performSegueWithIdentifier:@"Motor Direct Thrust Segue" sender:nil];
}

- (void)updateUI{
    //update diameter label
    float diam = [SLUnitsConvertor displayUnitsOf:self.rocket.diameter forKey:DIAM_UNIT_KEY];
    NSString *diamUnits = [SLUnitsConvertor displayStringForKey:DIAM_UNIT_KEY];
    self.diamLabel.text = [NSString stringWithFormat:@"%1.1f %@", diam, diamUnits];
    
    //update mass label
    float mass = [SLUnitsConvertor displayUnitsOf:self.rocket.massWithMotors forKey:MASS_UNIT_KEY];
    NSString *massUnits = [SLUnitsConvertor displayStringForKey:MASS_UNIT_KEY];
    self.liftMassLabel.text = [NSString stringWithFormat:@"%1.1f %@", mass, massUnits];
    
    //update motor cell
    self.motorManufacturerLogoImageView.image = [UIImage imageNamed:self.motor.manufacturer];
    self.motorShortNameLabel.text = self.motor.name;
    self.motorTotalImpulseLabel.text = [NSString stringWithFormat:@"%1.1f Ns", self.motor.totalImpulse];
}

- (void)updateModel{
    NSArray *loadOut = @[@{MOTOR_COUNT_KEY : @1, MOTOR_PLIST_KEY : [self.motor motorDict]}];
    [self.rocket replaceMotorLoadOutWithLoadOut:loadOut];
}

#pragma mark - SLSimulationDelegate methods

- (void)sender:(id)sender didChangeSimSettings:(NSDictionary *)settings withUpdate:(BOOL)update{
    // not sure I want to respond to this
}

- (void)sender:(id)sender didChangeRocketMotor:(NSArray *)motorPlist{
    NSDictionary *firstMotor = [motorPlist firstObject];
    self.motor = [RocketMotor motorWithMotorDict:firstMotor[MOTOR_PLIST_KEY]];
    [self updateModel];
    [self updateUI];
}

#pragma mark - SLSimulationDataSource methods

-(NSMutableDictionary *)simulationSettings{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults objectForKey:SETTINGS_KEY] mutableCopy];
}

-(float)freeFlightVelocity{
    return [self.model velocityAtEndOfLaunchGuide];
}
-(float)freeFlightAoA{
    return [self.model freeFlightAngleOfAttack];
}
-(float)windVelocity{
    return 0.0;
}
-(float)launchAngle{
    return 0.0;
}
-(float)launchGuideLength;
{
    return 0.923;//36 inches
}
-(float)launchSiteAltitude;
{
    return 0.0;
}
-(LaunchDirection)launchGuideDirection;
{
    return CrossWind;
}
-(float)quickFFVelocityAtAngle:(float)angle andGuideLength:(float)length;
{
    return [self.model quickFFVelocityAtLaunchAngle:angle andGuideLength:length];
}

- (NSString *)avatarName{
    return self.rocket.avatar;
}

- (void)viewDidLoad {
    [super viewDidLoad];
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
    self.model = [[SLPhysicsModel alloc] init];
    self.rocket = [Rocket defaultRocket];
    self.rocket.cd = 0.5f;
    self.motor = [RocketMotor defaultMotor];
    NSArray *loadOut = @[@{MOTOR_COUNT_KEY : @1, MOTOR_PLIST_KEY : [self.motor motorDict]}];
    [self.rocket replaceMotorLoadOutWithLoadOut:loadOut];
    self.model.rocket = self.rocket;
    [self updateUI];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"Motor Search Segue"]){
        SLMotorSearchViewController *dvc = segue.destinationViewController;
        dvc.popBackController = self;
        dvc.delegate = self;
    }
    if ([segue.identifier isEqualToString:@"Vector View Segue"]){
        SLAnimatedViewController *dvc = segue.destinationViewController;
        dvc.delegate = self;
        dvc.dataSource = self;
    }
    if ([segue.identifier isEqualToString:@"Motor Direct Thrust Segue"]){
        SLClusterMotorViewController *dvc = segue.destinationViewController;
        dvc.popBackViewController = self;
        dvc.delegate = self;
        dvc.motorLoadoutPlist = self.rocket.motorLoadoutPlist;
    }
}


@end
