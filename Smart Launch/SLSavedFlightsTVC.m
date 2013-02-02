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

@property (nonatomic, strong) NSArray *savedFlights;

@end

@implementation SLSavedFlightsTVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.savedFlights count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SavedFlightCell";
    SLFlightDataCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
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



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSMutableArray *tempFlights = [self.savedFlights mutableCopy];
        [tempFlights removeObjectAtIndex:indexPath.row];
        self.savedFlights = [tempFlights copy];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
