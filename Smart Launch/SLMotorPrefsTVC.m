//
//  SLMotorPrefsTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 9/5/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLMotorPrefsTVC.h"
#import "SLDefinitions.h"
#import "RocketMotor.h"

@interface SLMotorPrefsTVC ()

// model = dictionary of NSNumber BOOL values telling the App whether to display motors with the keys
// (manufacturer, diameter, impulse class)
@property (nonatomic, strong) NSMutableDictionary *motorPrefs;
// a temporary holder to undo changes
@property (nonatomic, strong) NSMutableDictionary *oldMotorPrefs;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *hybridButton;
@property (nonatomic) BOOL showingHybrids;

@end

@implementation SLMotorPrefsTVC

@synthesize motorPrefs = _motorPrefs;
@synthesize oldMotorPrefs = _oldMotorPrefs;

- (NSMutableDictionary*)motorPrefs{
    if (!_motorPrefs){
        _motorPrefs = [NSMutableDictionary dictionaryWithCapacity:64];
        for (NSString *key in [RocketMotor manufacturerNames]) [_motorPrefs setObject:[NSNumber numberWithBool:YES] forKey:key];
        for (NSString *key in [RocketMotor motorDiameters]) [_motorPrefs setObject:[NSNumber numberWithBool:YES] forKey:key];
        for (NSString *key in [RocketMotor impulseClasses]) [_motorPrefs setObject:[NSNumber numberWithBool:YES] forKey:key];
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

- (IBAction)toggleHybrids:(UIBarButtonItem *)sender {
    if (self.showingHybrids){
        // we should hide, so hide the motor manufacturers,and change the button name to "show"
        [self.hybridButton setTitle:@"Show Hybrids"];
    }else{
        // we should stop hiding them, change the button back to "Hide"
        [self.hybridButton setTitle:@"Hide Hybrids"];
    }
    BOOL newState = !self.showingHybrids;
    for (NSString *man in [RocketMotor hybridManufacturerNames]){
        self.motorPrefs[man] = @(newState);
    }
    self.showingHybrids = !self.showingHybrids;
    [self.tableView reloadData];
}

- (IBAction)savePrefsAndReturn:(id)sender {
    // if we haven't changed anything, just pop back
    if (![self.motorPrefs isEqualToDictionary:self.oldMotorPrefs]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.motorPrefs forKey:MOTOR_PREFS_KEY];
        [defaults synchronize];
        
        // find out if there is a cache of the motor data, if so, delete it to force re-initialization with the new prefs
        NSURL *cacheURL =[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *motorFileURL = [cacheURL URLByAppendingPathComponent:MOTOR_CACHE_FILENAME];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[motorFileURL path]]){
            [[NSFileManager defaultManager] removeItemAtURL:motorFileURL error:nil];
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - View Lifecycle


- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:NO animated:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.motorPrefs = [[defaults objectForKey:MOTOR_PREFS_KEY] mutableCopy];
    // notice here that if _motorPrefs is left nil above, the following line will fill both dictionaries with YES values
    self.oldMotorPrefs = [self.motorPrefs copy];
    self.showingHybrids = [defaults boolForKey:SHOWING_HYBRIDS_KEY];
    if (self.showingHybrids){
        [self.hybridButton setTitle:@"Hide Hybrids"];
    }else{
        [self.hybridButton setTitle:@"Show Hybrids"];
    }

    [super viewWillAppear:animated];
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
            return [[RocketMotor manufacturerNames] count];
        case 1:
            return [[RocketMotor motorDiameters] count];
        case 2:
            return [[RocketMotor impulseClasses] count];
            
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
            cellText = [[RocketMotor manufacturerNames] objectAtIndex:indexPath.row];
            cell.imageView.image = [UIImage imageNamed:cellText];
            break;
        case 1:
            cellText = [[RocketMotor motorDiameters] objectAtIndex:indexPath.row];
            cell.imageView.image = nil;
            break;
        case 2:
            cellText = [[RocketMotor impulseClasses] objectAtIndex:indexPath.row];
            cell.imageView.image = nil;
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
        [self.motorPrefs setObject:@(NO) forKey:motorKey];
    }else{
        // it is not selected, select it and record the selection
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [self.motorPrefs setObject:@(YES) forKey:motorKey];
    }
}

#pragma mark - SLMotorPrefsTVC class methods

+ (NSDictionary *)motorKeysAllSelected{
    NSMutableDictionary* buildDict = [NSMutableDictionary dictionaryWithCapacity:64];
    for (NSString *key in [RocketMotor manufacturerNames]) [buildDict setObject:[NSNumber numberWithBool:YES] forKey:key];
    for (NSString *key in [RocketMotor motorDiameters]) [buildDict setObject:[NSNumber numberWithBool:YES] forKey:key];
    for (NSString *key in [RocketMotor impulseClasses]) [buildDict setObject:[NSNumber numberWithBool:YES] forKey:key];
    return [buildDict copy];
}


@end
