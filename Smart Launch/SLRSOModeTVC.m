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
@property (weak, nonatomic) IBOutlet UIPickerView *diameterPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *massPicker;
@property (weak, nonatomic) IBOutlet UILabel *thrustWeightLabel;

@property (nonatomic) BOOL showingMassPicker;
@property (nonatomic) BOOL showingDiameterPicker;


@end

@implementation SLRSOModeTVC
{
    NSNumberFormatter *nf;
    NSArray *digits;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    if (pickerView == self.diameterPicker){
        return 4;
    }else{// pickerView == massPicker
        return 5;
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if (pickerView == self.massPicker){
        switch (component) {
            case 0:
                return 3;
            case 1:
                return 10;
            case 2:
                return 10;
            case 3:
                return 1;
            case 4:
                return 10;
            default:
                break;
        }
    }else{// pickerView == diameterPicker
        switch (component) {
            case 0:
                return 10;
            case 1:
                return 10;
            case 2:
                return 1;
            case 3:
                return 10;
            default:
                break;
        }
    }
    return 0;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    if (pickerView == self.massPicker) component -= 1;
    if (component == 2) return @".";
    return [NSString stringWithFormat:@"%ld", row];
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    if (pickerView == self.diameterPicker){
        self.rocket.diameter = [SLUnitsConvertor metricStandardOf:[self diameterPickerValue] forKey:DIAM_UNIT_KEY];
    }else{//pickerView == self.massPicker
        float loadedMass = [SLUnitsConvertor metricStandardOf:[self massPickerValue] forKey:MASS_UNIT_KEY];
        self.rocket.mass = loadedMass - self.motor.loadedMass;
    }
    [self updateUI];
}

- (void)setDiameterPickerValue:(float)value{
    NSString *s = [NSString stringWithFormat:@"%02.1f", value];
    NSMutableArray *chars = [NSMutableArray new];
    for (int i = 0; i < [s length]; i++){
        [chars addObject:[NSString stringWithFormat:@"%c", [s characterAtIndex:i]]];
    }
    if ([chars count] < 4){
        for (int j = 0; j < 4 - [chars count]; j++){
            chars = [[@[@"0"] arrayByAddingObjectsFromArray:chars] mutableCopy];
        }
    }
    NSAssert([chars count] == 4, @"Wrong number of characters found");
    for (int i = 0; i < 4; i++){
        NSString *c = chars[i];
        if ([c isEqualToString:@"."]) continue;
        NSInteger n = [[nf numberFromString:c] integerValue];
        [self.diameterPicker selectRow:n inComponent:i animated:YES];
    }
}

- (void)setMassPickerValue:(float)value{
    NSString *s = [NSString stringWithFormat:@"%03.1f", value];
    NSMutableArray *chars = [NSMutableArray new];
    for (int i = 0; i < [s length]; i++){
        [chars addObject:[NSString stringWithFormat:@"%c", [s characterAtIndex:i]]];
    }
    if ([chars count] < 5){
        NSInteger ct = [chars count];
        for (int j = 0; j < 5 - ct; j++){
            chars = [[@[@"0"] arrayByAddingObjectsFromArray:chars] mutableCopy];
        }
    }
    NSAssert([chars count] == 5, @"Wrong number of characters found");
    for (int i = 0; i < 5; i++){
        NSString *c = chars[i];
        if ([c isEqualToString:@"."]) continue;
        NSInteger n = [[nf numberFromString:c] integerValue];
        [self.massPicker selectRow:n inComponent:i animated:YES];
    }
}

- (float)diameterPickerValue{
    //get an array of the individual component values as NSString*
    NSMutableArray *comps = [NSMutableArray new];
    for (int i = 0; i < [self.diameterPicker numberOfComponents]; i++){
        NSString * digit;
        if (i == 2){
            digit = @".";
        }else{
            NSInteger selection = [self.diameterPicker selectedRowInComponent:i];
            digit = digits[selection];
        }
        [comps addObject:digit];
    }
    NSString *value = [comps componentsJoinedByString:@""];
    return [[nf numberFromString:value] floatValue];
}

- (float)massPickerValue{
    //get an array of the individual component values as NSString*
    NSMutableArray *comps = [NSMutableArray new];
    for (int i = 0; i < [self.massPicker numberOfComponents]; i++){
        NSString * digit;
        if (i == 3){
            digit = @".";
        }else{
            NSInteger selection = [self.massPicker selectedRowInComponent:i];
            digit = digits[selection];
        }
        [comps addObject:digit];
    }
    NSString *value = [comps componentsJoinedByString:@""];
    return [[nf numberFromString:value] floatValue];
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0){
        if (self.showingDiameterPicker){
            //hide it
            self.showingDiameterPicker = NO;
        }else{
            //show it and hide the other one if showing
            self.showingDiameterPicker = YES;
            self.showingMassPicker = NO;
        }
        [tableView beginUpdates];
        [tableView reloadData];
        [tableView endUpdates];
        float diam = [SLUnitsConvertor displayUnitsOf:self.rocket.diameter forKey:DIAM_UNIT_KEY];
        [self setDiameterPickerValue:diam];
        
    }else if (indexPath.row == 2){
        if (self.showingMassPicker){
            //hide it
            self.showingMassPicker = NO;
        }else{
            //show it and hide the other one
            self.showingMassPicker = YES;
            self.showingDiameterPicker = NO;
        }
        [tableView beginUpdates];
        [tableView reloadData];
        [tableView endUpdates];
        float mass = [SLUnitsConvertor displayUnitsOf:self.rocket.massWithMotors forKey:MASS_UNIT_KEY];
        [self setMassPickerValue:mass];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 1){
        return self.showingDiameterPicker ? 216.0 : 0.0;
    }else if (indexPath.row == 3){
        return self.showingMassPicker ? 216.0 : 0.0;
    }else{
        return UITableViewAutomaticDimension;
    }
}

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
    
    //update thrust to weight ratio
    NSString *twr = [NSString stringWithFormat:@"%1.1f : 1", ([self.rocket peakThrust])/(self.rocket.massWithMotors * GRAV_ACCEL)];
    self.thrustWeightLabel.text = twr;
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
    return 0.5;
}
-(float)launchAngle{
    return 0.1;
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
    nf = [[NSNumberFormatter alloc] init];
    digits = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
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
