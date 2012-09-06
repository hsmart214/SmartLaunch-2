//
//  SLMotorPrefsTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 9/5/12.
//  Copyright (c) 2012 J. HOWARD SMART. All rights reserved.
//

#import "SLMotorPrefsTVC.h"
#import "SLDefinitions.h"

@interface SLMotorPrefsTVC ()

@property (nonatomic, strong) NSArray *manufacturerNames;
@property (nonatomic, strong) NSArray *impulseClasses;
@property (nonatomic, strong) NSArray *motorDiameters;
// model = dictionary of NSNumber BOOL values telling the App whether to display motors with the keys
// (manufacturer, diameter, impulse class)
@property (nonatomic, strong) NSMutableDictionary *motorPrefs;
// a temporary holder to undo changes
@property (nonatomic, strong) NSMutableDictionary *oldMotorPrefs;

@end

@implementation SLMotorPrefsTVC

@synthesize manufacturerNames = _manufacturerNames;
@synthesize impulseClasses = _impulseClasses;
@synthesize motorDiameters = _motorDiameters;
@synthesize motorPrefs = _motorPrefs;
@synthesize oldMotorPrefs = _oldMotorPrefs;

- (NSArray *)manufacturerNames{
    if (!_manufacturerNames){
        _manufacturerNames = [NSArray arrayWithObjects:
                              @"AMW Pro-X", 
                              @"Aerotech RMS",
                              @"Aerotech",
                              @"Aerotech Hybrid",
                              @"Animal Motor Works",
                              @"Apogee",
                              @"Cesaroni",
                              @"Contrail Rockets",
                              @"Ellis Mountain",
                              @"Estes",
                              @"Gorilla Rocket Motors",
                              @"Hypertek",
                              @"Kosdon by Aerotech",
                              @"Kosdon",
                              @"Loki Research",
                              @"Public Missiles Ltd",
                              @"Propulsion Polymers",
                              @"Quest",
                              @"RATTworks",
                              @"RoadRunner",
                              @"Sky Ripper",
                              @"West Coast Hybrids", nil];
    }
    return _manufacturerNames;
}

- (NSArray *)impulseClasses{
    if (!_impulseClasses){
        _impulseClasses = [NSArray arrayWithObjects:@"1/8 A", @"1/4 A", @"1/2 A", @"A", @"B", @"C", @"D",
                           @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", nil];
    }
    return _impulseClasses;
}

- (NSArray  *)motorDiameters{
    if (!_motorDiameters){
        _motorDiameters = [NSArray arrayWithObjects:@"6mm", @"13mm", @"18mm", @"24mm", @"29mm",
                           @"38mm", @"54mm", @"75mm", @"98mm", @"150mm", nil];
    }
    return _motorDiameters;
}

- (NSMutableDictionary*)motorPrefs{
    if (!_motorPrefs){
        _motorPrefs = [NSMutableDictionary dictionaryWithCapacity:64];
        for (NSString *key in self.manufacturerNames) [_motorPrefs setObject:[NSNumber numberWithBool:YES] forKey:key];
        for (NSString *key in self.motorDiameters) [_motorPrefs setObject:[NSNumber numberWithBool:YES] forKey:key];
        for (NSString *key in self.impulseClasses) [_motorPrefs setObject:[NSNumber numberWithBool:YES] forKey:key];
    }
    return _motorPrefs;
}

#pragma mark - Target Action methods

- (IBAction)selectAllMotorKeys:(id)sender {
    // this leaves oldMotorPrefs alone so we can still revert
    _motorPrefs = nil; // the getter for motorPrefs will re-initialize with all YES
    [self.tableView reloadData];
}

- (IBAction)revertPrefs:(id)sender {
    self.motorPrefs = self.oldMotorPrefs;
    [self.tableView reloadData];
}

- (IBAction)savePrefsAndReturn:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.motorPrefs forKey:MOTOR_PREFS_KEY];
    [defaults synchronize];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.motorPrefs = [[defaults objectForKey:MOTOR_PREFS_KEY] mutableCopy];
    // notice here that if _motorPrefs is left nil above, the following line will fill both dictionaries with YES values
    self.oldMotorPrefs = self.motorPrefs;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return NSLocalizedString(@"Motor Manufacturers", nil);
        case 1:
            return NSLocalizedString(@"Motor Diameters", nil);
        case 2:
            return NSLocalizedString(@"Impulse Classes", nil);
        default:
            return @"You should not see this";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return [self.manufacturerNames count];
        case 1:
            return [self.motorDiameters count];
        case 2:
            return [self.impulseClasses count];
            
        default:
            return 0;   // should never reach this default
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Motor Prefs Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSString *cellText;
    switch (indexPath.section) {
        case 0:
            cellText = [self.manufacturerNames objectAtIndex:indexPath.row];
            break;
        case 1:
            cellText = [self.motorDiameters objectAtIndex:indexPath.row];
            break;
        case 2:
            cellText = [self.impulseClasses objectAtIndex:indexPath.row];
        default:
            break;
    }
    if ([[self.motorPrefs objectForKey:cellText] boolValue]){
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }else{
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    cell.textLabel.text = cellText;
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //toggle the checkmark and update the dictionary
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *motorKey = cell.textLabel.text;
    if ([cell accessoryType]== UITableViewCellAccessoryCheckmark){
        // it is selected, deselect it and record the deselection
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [self.motorPrefs setObject:[NSNumber numberWithBool:NO] forKey:motorKey];
    }else{
        // it is not selected, select it and record the selection
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [self.motorPrefs setObject:[NSNumber numberWithBool:YES] forKey:motorKey];
    }
}

@end
