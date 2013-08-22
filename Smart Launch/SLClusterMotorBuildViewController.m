//
//  SLClusterMotorBuildViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterMotorBuildViewController.h"
#import "RocketMotor.h"
#import "SLMotorSearchViewController.h"
#import "SLSimulationDelegate.h"
#import "SLClusterMotorMemberCell.h"

@interface SLClusterMotorBuildViewController ()<SLMotorPickerDatasource, SLMotorGroupDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *autoUpdateBarButton;
@property (nonatomic) BOOL shouldUpdateContinuously;

@end

@implementation SLClusterMotorBuildViewController

@synthesize selectedGroupIndex = _selectedGroupIndex;
@synthesize motorConfiguration = _motorConfiguration;
@synthesize savedMotorLoadoutPlists = _savedMotorLoadoutPlists;
@synthesize motorLoadoutPlist = _motorLoadoutPlist;

-(NSArray *)motorLoadoutPlist{
    if (!_motorLoadoutPlist) {
        {NSMutableArray *arr = [NSMutableArray array];
            for (int i = 0; i < [self.motorConfiguration count]; i++) {
                [arr addObject:@{MOTOR_COUNT_KEY: self.motorConfiguration[i][MOTOR_COUNT_KEY]}];
            }
            _motorLoadoutPlist = [arr copy];
        }
    }
    return _motorLoadoutPlist;
}

- (IBAction)toggleAutoUpdate:(UIBarButtonItem *)sender {
    self.shouldUpdateContinuously = !self.shouldUpdateContinuously;
    if (self.shouldUpdateContinuously){
        [sender setTitle:NSLocalizedString(@"Auto Update: ON", @"text for interface auto-update toggle ON")];
        [self.simDelegate sender:self didChangeRocketMotor:self.motorLoadoutPlist];
        NSDictionary *settings = [self.simDatasource simulationSettings];
        [self.simDelegate sender:self didChangeSimSettings:settings withUpdate:YES];
    }else{
        [sender setTitle:NSLocalizedString(@"Auto Update: OFF", @"text for interface auto-update toggle OFF")];
    }
}

-(void)setMotorLoadoutPlist:(NSArray *)motorLoadoutPlist{
    _motorLoadoutPlist = motorLoadoutPlist;
    int diff = [self.motorConfiguration count] - [motorLoadoutPlist count];
    if (diff > 0){
        NSMutableArray *arr = [motorLoadoutPlist mutableCopy];
        for (int i = 0; i < diff; i++){
            [arr addObject:@{}];
        }
        _motorLoadoutPlist = [arr copy];
    }
}

#pragma mark - SLClusterBuildDelegate/Datasource methods

-(void)changeDelayTimeTo:(float)delay forGroupAtIndex:(NSUInteger)index{
    NSMutableDictionary *motorDict = [self.motorLoadoutPlist[index][MOTOR_PLIST_KEY] mutableCopy];
    NSNumber *count = self.motorLoadoutPlist[index][MOTOR_COUNT_KEY];
    motorDict[CLUSTER_START_DELAY_KEY] = @(delay);
    NSMutableArray *arr = [self.motorLoadoutPlist mutableCopy];
    [arr replaceObjectAtIndex:index withObject:@{MOTOR_COUNT_KEY: count,
                                                 MOTOR_PLIST_KEY: motorDict}];
    self.motorLoadoutPlist = [arr copy];
    [self.tableView reloadData];
    if (self.splitViewController && self.shouldUpdateContinuously){
        [self.simDelegate sender:self didChangeRocketMotor:self.motorLoadoutPlist];
        NSDictionary *settings = [self.simDatasource simulationSettings];
        [self.simDelegate sender:self didChangeSimSettings:settings withUpdate:YES];
    }
}

-(void)replaceMotorLoadoutPlist:(NSArray *)motorLoadoutPlist{
    self.motorLoadoutPlist = motorLoadoutPlist;
    [self.simDelegate sender:self didChangeRocketMotor:self.motorLoadoutPlist];
}

-(void)deleteSavedMotorLoadoutAtIndex:(NSUInteger)index{
    NSMutableArray *arr = [self.savedMotorLoadoutPlists mutableCopy];
    [arr removeObjectAtIndex:index];
    self.savedMotorLoadoutPlists = [arr copy];
}


#pragma mark - SLSimulationDelegate method

-(void)sender:(id)sender didChangeRocketMotor:(NSArray *)motor{
    NSMutableDictionary *dict;
    if (![motor count]) {
        dict = [NSMutableDictionary dictionary];
    }else{
        dict = [motor[0] mutableCopy];
        dict[MOTOR_COUNT_KEY] = self.motorConfiguration[self.selectedGroupIndex][MOTOR_COUNT_KEY];
    }
    NSMutableArray *arr = [self.motorLoadoutPlist mutableCopy];
    if (!self.selectedGroupIndex && ![arr count]){
        [arr addObject:dict];
    }else{
        [arr replaceObjectAtIndex:self.selectedGroupIndex withObject:dict];
    }
    self.motorLoadoutPlist = [arr copy];
    [self.tableView reloadData];
    if (self.splitViewController){
        [self.simDelegate sender:self didChangeRocketMotor:self.motorLoadoutPlist];
        NSDictionary *settings = [self.simDatasource simulationSettings];
        [self.simDelegate sender:self didChangeSimSettings:settings withUpdate:YES];
        }
}

-(NSUInteger)motorSizeRequested{
    return [self.motorConfiguration[self.selectedGroupIndex][MOTOR_DIAM_KEY] integerValue];
}

-(void)SLClusterMotorMemberCell:(SLClusterMotorMemberCell *)sender didChangeStartDelay:(float)time{
    NSUInteger row = [self.tableView indexPathForCell:sender].row;
    RocketMotor *motor = [RocketMotor motorWithMotorDict:self.motorLoadoutPlist[row][MOTOR_PLIST_KEY]];
    motor.startDelay = time;
    NSMutableArray *arr = [self.motorLoadoutPlist mutableCopy];
    NSNumber *count = self.motorLoadoutPlist[row][MOTOR_COUNT_KEY];
    [arr replaceObjectAtIndex:row withObject:@{MOTOR_COUNT_KEY: count,
                                              MOTOR_PLIST_KEY: [motor motorDict]}];
    self.motorLoadoutPlist = [arr copy];
    [self.tableView reloadData];
    if (self.splitViewController && self.shouldUpdateContinuously){
        [self.simDelegate sender:self didChangeRocketMotor:self.motorLoadoutPlist];
        NSDictionary *settings = [self.simDatasource simulationSettings];
        [self.simDelegate sender:self didChangeSimSettings:settings withUpdate:YES];
    }
}

-(BOOL)allowsSimulationUpdates{
    return [self.delegate shouldAllowSimulationUpdates];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.motorConfiguration count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    SLClusterMotorMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:@"clusterMemberCell"];
    cell.motorMountSizeLabel.text = [NSString stringWithFormat:@"%dmm", [self.motorConfiguration[indexPath.row][MOTOR_DIAM_KEY] integerValue]];
    cell.motorCountTextLabel.text = [NSString stringWithFormat:@"x %d", [self.motorConfiguration[indexPath.row][MOTOR_COUNT_KEY] integerValue]];
    cell.delegate = self;

    // need to check for the existence of motors in the loadout
    if (self.motorLoadoutPlist[indexPath.row][MOTOR_PLIST_KEY]){
        // we have at least this many loaded groups, so we can load the info
        NSDictionary *motorDict = self.motorLoadoutPlist[indexPath.row][MOTOR_PLIST_KEY];
        RocketMotor *motor = [RocketMotor motorWithMotorDict:motorDict];
        NSString *manName = [motor manufacturer];
        cell.manufacturerLogoImageView.image = [UIImage imageNamed:manName];
        cell.motorNameLabel.text = motor.name;
        cell.motorDetailTextLabel.text = [NSString stringWithFormat:@"%1.1f Ns", [motor totalImpulse]];
        cell.delayTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Delay %1.1f sec", @"Delay %1.1f sec") , motor.startDelay];
        [cell.delayTimeStepper setValue:motor.startDelay];
        cell.oldStartDelayValue = motor.startDelay;
        [cell.delayTimeStepper setEnabled:YES];
        float btime = [[motor.times lastObject] floatValue];
        cell.burnTimeTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Burn Length %1.1f sec", @"Burn Length %1.1f sec") , btime];
        cell.burnoutTimeTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Burnout Time %1.1f sec", @"Burnout Time %1.1f sec") , btime + motor.startDelay];
    }else{
        // load up the empty row so the user can fill it if they like
        cell.manufacturerLogoImageView.image = nil;
        cell.motorNameLabel.text = NSLocalizedString(@"No Motor", @"No Motor Selected");
        cell.motorDetailTextLabel.text = @"";
        cell.delayTextLabel.text = NSLocalizedString(@"Delay 0.0 sec", @"Delay 0.0 sec") ;
        [cell.delayTimeStepper setValue:0.0];
        cell.oldStartDelayValue = 0.0;
        [cell.delayTimeStepper setEnabled:NO];
    }
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedGroupIndex = indexPath.row;
    [self performSegueWithIdentifier:@"clusterMemberMotorSearch" sender:indexPath];
}

//-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
//    
//}

#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"clusterMemberMotorSearch"]) {
        [(SLMotorSearchViewController *)segue.destinationViewController setDataSource:self];
        [(SLMotorSearchViewController *)segue.destinationViewController setDelegate:self];
        [(SLMotorSearchViewController *)segue.destinationViewController setPopBackController:self];
    }
    if ([segue.identifier isEqualToString:@"savedClusterSegue"]){
        [(SLClusterTableViewController *)segue.destinationViewController setClusterDelegate:self];
        [(SLClusterTableViewController *)segue.destinationViewController setClusterDatasource:self];
        [(SLClusterTableViewController *)segue.destinationViewController setMotorLoadouts:self.savedMotorLoadoutPlists];
    }
}

-(void)viewDidLoad{
    [super viewDidLoad];
    if (!self.splitViewController){
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }else{
        //self.tableView.backgroundColor = [SLCustomUI iPadBackgroundColor];
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_FOR_IPAD_MASTER_VC];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }
    if (self.autoUpdateBarButton){
        [self.autoUpdateBarButton setTitle:NSLocalizedString(@"Auto Update: ON", @"text for interface auto-update toggle ON")];
        self.shouldUpdateContinuously = YES;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.simDelegate sender:self didChangeRocketMotor:self.motorLoadoutPlist];
}

-(void)dealloc{
    self.motorConfiguration = nil;
    self.motorLoadoutPlist = nil;
    self.savedMotorLoadoutPlists = nil;
}

@end
