//
//  SLSavedFlightsTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 1/12/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

/* This controller needs to respond to iCloud updates because it holds a strong Rocket*
 which may change externally */

#import "SLSavedFlightsTVC.h"
#import "SLFlightDataCell.h"
#import "SLUnitsConvertor.h"

@interface SLSavedFlightsTVC ()

@property (nonatomic, strong) NSMutableArray *savedFlights;
@property (nonatomic, strong) NSArray *originalSavedFlights;
@property (nonatomic, strong) id iCloudObserver;

@end

@implementation SLSavedFlightsTVC

- (NSMutableArray *)savedFlights{
    if(!_savedFlights){
        _savedFlights = [self.rocket.recordedFlights mutableCopy];
    }
    return _savedFlights;
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
    
    if (!cell){
        cell = [[SLFlightDataCell alloc] init];
    }
    
    cell.motorName.text = self.savedFlights[indexPath.row][FLIGHT_MOTOR_KEY];
    cell.cd.text = [NSString stringWithFormat:@"%1.2f", [self.savedFlights[indexPath.row][FLIGHT_BEST_CD] floatValue]];
    cell.altitudeUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    NSNumber *alt = self.savedFlights[indexPath.row][FLIGHT_ALTITUDE_KEY];
    alt = [SLUnitsConvertor displayUnitsOf:alt forKey:ALT_UNIT_KEY];
    cell.altitude.text = [NSString stringWithFormat:@"%1.0f", [alt floatValue]];
    
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
}

#pragma mark View life cycle

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:NO animated:animated];
    self.originalSavedFlights = [self.savedFlights copy];
    
    self.iCloudObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                                            object:nil
                                                                             queue:nil
                                                                        usingBlock:^(NSNotification *notification){
        /* This is the block */
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *changedKeys = [[notification userInfo] objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        for (NSString *key in changedKeys) {
            [defaults setObject:[store objectForKey:key] forKey:key];       // right now this can only be the favorite rockets dictionary
        }
        NSDictionary *possiblyChangedRocket = [defaults dictionaryForKey:FAVORITE_ROCKETS_KEY][self.rocket.name];
        if (possiblyChangedRocket){
            self.rocket = [Rocket rocketWithRocketDict:possiblyChangedRocket];
        }else{// somebody on another device deleted this rocket, so we will put it right back in!
            NSMutableDictionary *savedRockets = [[defaults dictionaryForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
            [savedRockets setObject:[self.rocket rocketPropertyList] forKey:self.rocket.name];
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
@end
