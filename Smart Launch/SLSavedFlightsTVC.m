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
    //NSString *motorName = self.savedFlights[self.selectedFlightRow][FLIGHT_MOTOR_LONGNAME_KEY];
    //RocketMotor *motor = [self motorNamed:motorName];
    NSDictionary *motorDict = settings[SELECTED_MOTOR_KEY];
    RocketMotor *motor = [RocketMotor motorWithMotorDict:motorDict];
    if (!motor) return;
    
    [self.simDelegate sender:self didChangeRocket:self.rocket];
    [self.simDelegate sender:self didChangeRocketMotor:motor];
    [self.simDelegate sender:self didChangeSimSettings:settings withUpdate:YES];
}

//-(RocketMotor *)motorNamed:(NSString *)name{
//    if (!name) return nil; // this would mean the flight was saved in a previous version so the full name was not saved
//
//    NSDictionary *allMotorsDictionary;
//    NSArray *allMotors;
//    NSDictionary *motorDict;
//    NSURL *cacheURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
//    NSURL *motorHashFileURL = [cacheURL URLByAppendingPathComponent:EVERY_MOTOR_HASHTABLE_CACHE_FILENAME];
//    NSURL *motorFileURL = [cacheURL URLByAppendingPathComponent:EVERY_MOTOR_CACHE_FILENAME];
//    if ([[NSFileManager defaultManager]fileExistsAtPath:[motorHashFileURL path]]){
//        allMotorsDictionary = [NSDictionary dictionaryWithContentsOfURL:motorHashFileURL];
//        motorDict = allMotorsDictionary[name];
//    // that would be fairly fast, on the other hand this will be slow
//    // but this should only happen if they have not regenerated their caches since their upgrade
//    }else if ([[NSFileManager defaultManager]fileExistsAtPath:[motorFileURL path]]){
//        allMotors = [NSArray arrayWithContentsOfURL:motorFileURL];
//        for (NSDictionary *dict in allMotors){
//            NSString *motorName = [NSString stringWithFormat:@"%@ %@", dict[MAN_KEY], dict[NAME_KEY]];
//            if ([motorName isEqualToString:name]){
//                motorDict = dict;
//                break;
//            }
//        }
//    }else{
//        return nil; // this is if there are no cache files at all.  Carry on like nothing happened.
//    }
//    return [RocketMotor motorWithMotorDict:motorDict];
//}

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
    
    if (!cell){
        cell = [[SLFlightDataCell alloc] init];
    }
    
    cell.motorName.text = self.savedFlights[indexPath.row][FLIGHT_MOTOR_KEY];
    cell.cd.text = [NSString stringWithFormat:@"%1.2f", [self.savedFlights[indexPath.row][FLIGHT_BEST_CD] floatValue]];
    cell.altitudeUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    NSNumber *alt = self.savedFlights[indexPath.row][FLIGHT_ALTITUDE_KEY];
    alt = [SLUnitsConvertor displayUnitsOf:alt forKey:ALT_UNIT_KEY];
    cell.altitude.text = [NSString stringWithFormat:@"%1.0f", [alt floatValue]];
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
}

-(void)viewWillAppear:(BOOL)animated{
    self.selectedFlightRow = -1;
    [self.navigationController setToolbarHidden:NO animated:animated];
    self.originalSavedFlights = [self.savedFlights copy];
    
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
        NSDictionary *possiblyChangedRocket = [defaults dictionaryForKey:FAVORITE_ROCKETS_KEY][self.rocket.name];
        if (possiblyChangedRocket){
            self.rocket = [Rocket rocketWithRocketDict:possiblyChangedRocket];
        }else{// somebody on another device deleted this rocket, so we will put it right back in!
            NSMutableDictionary *savedRockets = [[defaults dictionaryForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
            savedRockets[self.rocket.name] = [self.rocket rocketPropertyList];
            [defaults setObject:savedRockets forKey:FAVORITE_ROCKETS_KEY];
            [store setDictionary:savedRockets forKey:FAVORITE_ROCKETS_KEY];
        }
        self.savedFlights = [self.rocket.recordedFlights mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
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
