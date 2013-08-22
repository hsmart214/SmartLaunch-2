//
//  SLSavedFlightsTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 1/12/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//


#import "SLSavedFlightsTVC.h"
#import "SLFlightDataCell.h"
#import "SLUnitsConvertor.h"
#import "RocketMotor.h"
#import "SLClusterMotor.h"

@interface SLSavedFlightsTVC ()

@property (nonatomic, strong) NSMutableArray *savedFlights;
@property (nonatomic, strong) NSArray *originalSavedFlights;
@property (nonatomic) NSUInteger selectedFlightRow;
@property (nonatomic, strong) id iCloudObserver;

@end

@implementation SLSavedFlightsTVC

- (NSMutableArray *)savedFlights{
    if(!_savedFlights){
        _savedFlights = [self.rocket.recordedFlights mutableCopy];
    }
    return _savedFlights;
}

/*
    Here is what is in a "settings" dict:
 settings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
 @0.9, WIND_VELOCITY_KEY,             //2 MPH
 @0.9144, LAUNCH_GUIDE_LENGTH_KEY,    //36 inches
 @0.0, LAUNCH_ANGLE_KEY,
 @33.0, LAUNCH_ALTITUDE_KEY,          //100 feet
 @motorLoadoutPlist, SELECTED_MOTOR_KEY,
 nil];

 */

-(void)pushFlightData{
    if (!self.splitViewController) return;
    //Only do this next part on the iPad
    NSDictionary *settings = self.savedFlights[self.selectedFlightRow][FLIGHT_SETTINGS_KEY];
    if (!settings) {
        // If the recorded flight does not include settings - it is from a previous version. Uncheck the row and do nothing
        self.selectedFlightRow = -1;
        [self.tableView reloadData];
        return;
    }
    [self.simDelegate sender:self didChangeRocket:self.rocket];
    id motorObject = settings[SELECTED_MOTOR_KEY];
    if ([motorObject isKindOfClass:[NSDictionary class]]){
        // It is a single motor
        [self.simDelegate sender:self didChangeRocketMotor:@[@{MOTOR_COUNT_KEY: @1,
             MOTOR_PLIST_KEY: motorObject}]];
    }else if([motorObject isKindOfClass:[NSArray class]]){
        // It is a cluster plist array
        [self.simDelegate sender:self didChangeRocketMotor: motorObject];
    }
    [self.simDelegate sender:self didChangeSimSettings:settings withUpdate:YES];
}

#pragma mark - Target action

- (IBAction)save:(UIBarButtonItem *)sender {
    [self.rocketDelegate SLSavedFlightsTVC:self didUpdateSavedFlights:[self.savedFlights copy]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    //pop back without changing a thing
    self.rocket.recordedFlights = self.originalSavedFlights;
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)revert:(UIBarButtonItem *)sender {
    self.savedFlights = [self.originalSavedFlights mutableCopy];
    [self.tableView reloadData];
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.savedFlights count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SLFlightDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SavedFlightCell" forIndexPath:indexPath];
    // find out if the saved record is an old one - pre-clusters
    // the settings has a complete motorPlist stashed away in it in SELECTED_MOTOR_KEY
    // if the version is 1.5 or higher, this will be an NSArray rather than a motorDict
    // versions 1.4 and previous did not have a SMART_LAUNCH_VERSION_KEY key at all, so it will be nil
    NSDictionary *flight = self.savedFlights[indexPath.row];
    NSString *motorName;
    if (flight[SMART_LAUNCH_VERSION_KEY]){
        NSUInteger totalMotors = 0;
        for (NSDictionary *dict in flight[FLIGHT_SETTINGS_KEY][SELECTED_MOTOR_KEY]) {
            totalMotors += [dict[MOTOR_COUNT_KEY] integerValue];
        }
        if (totalMotors == 1) {
            motorName = flight[MOTOR_PLIST_KEY][0][MOTOR_PLIST_KEY][NAME_KEY];
        }else{
            // must be a cluster - no flight can be saved with 0 motors!
            SLClusterMotor *cMotor = [[SLClusterMotor alloc] initWithMotorLoadout:flight[MOTOR_PLIST_KEY]];
            motorName = [cMotor description];
        }
        
    }else{
        motorName = flight[FLIGHT_MOTOR_KEY];
    }
    cell.motorName.text = motorName;
    cell.cd.text = [NSString stringWithFormat:@"%1.2f", [flight[FLIGHT_BEST_CD] floatValue]];
    cell.altitudeUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    float alt = [flight[FLIGHT_ALTITUDE_KEY] floatValue];
    alt = [SLUnitsConvertor displayUnitsOf:alt forKey:ALT_UNIT_KEY];
    cell.altitude.text = [NSString stringWithFormat:@"%1.0f", alt];
    if (self.selectedFlightRow == indexPath.row){
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }else{
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                            forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.savedFlights removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (!self.splitViewController) return;
    if (self.selectedFlightRow == indexPath.row) return;
    self.selectedFlightRow = indexPath.row;
    [tableView reloadData];
    [self pushFlightData]; // on the iPad this will cause the selected flight to be displayed on screen
}

#pragma mark View life cycle

-(void)viewDidLoad{
    [super viewDidLoad];
    // this is a terrible hack, but I need to add a chain of delegates to get around it
    self.simDelegate = self.navigationController.viewControllers[0];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        //self.tableView.backgroundColor = [SLCustomUI iPadBackgroundColor];
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_FOR_IPAD_MASTER_VC];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }else{ // iPhone or iPod
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }

}

-(void)viewWillAppear:(BOOL)animated{
    self.selectedFlightRow = -1;
    [self.navigationController setToolbarHidden:NO animated:animated];
    self.originalSavedFlights = [self.savedFlights copy];
    
    __weak SLSavedFlightsTVC *myWeakSelf = self;

    self.iCloudObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                                            object:nil
                                                                             queue:nil
                                                                        usingBlock:^(NSNotification *notification){
        /* This is the block */
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *changedKeys = [notification userInfo][NSUbiquitousKeyValueStoreChangedKeysKey];
        for (NSString *key in changedKeys) {
            [defaults setObject:[store objectForKey:key] forKey:key];       // right now this can only be the favorite rockets dictionary
        }
        NSDictionary *possiblyChangedRocket = [defaults dictionaryForKey:FAVORITE_ROCKETS_KEY][myWeakSelf.rocket.name];
        if (possiblyChangedRocket){
            myWeakSelf.rocket = [Rocket rocketWithRocketDict:possiblyChangedRocket];
        }else{// somebody on another device deleted this rocket, so we will put it right back in!
            NSMutableDictionary *savedRockets = [[defaults dictionaryForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
            savedRockets[myWeakSelf.rocket.name] = [myWeakSelf.rocket rocketPropertyList];
            [defaults setObject:savedRockets forKey:FAVORITE_ROCKETS_KEY];
            [store setDictionary:savedRockets forKey:FAVORITE_ROCKETS_KEY];
        }
        myWeakSelf.savedFlights = [myWeakSelf.rocket.recordedFlights mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [myWeakSelf.tableView reloadData];
        });
        [defaults synchronize];
    }];
    /* End of the block */
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self.iCloudObserver];
    self.iCloudObserver = nil;
}

-(void)dealloc{
    self.rocket = nil;
    self.savedFlights = nil;
    self.originalSavedFlights = nil;
}

-(NSString *)description{
    return @"SavedFlightsTVC";
}

@end
