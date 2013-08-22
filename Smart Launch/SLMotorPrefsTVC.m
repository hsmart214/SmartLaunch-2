//
//  SLMotorPrefsTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 9/5/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLMotorPrefsTVC.h"
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

- (NSMutableDictionary*)motorPrefs{
    if (!_motorPrefs){
        _motorPrefs = [NSMutableDictionary dictionaryWithCapacity:64];
        for (NSString *key in [RocketMotor manufacturerNames]) _motorPrefs[key] = @YES;
        for (NSString *key in [RocketMotor motorDiameters]) _motorPrefs[key] = @YES;
        for (NSString *key in [RocketMotor impulseClasses]) _motorPrefs[key] = @YES;
    }
    return _motorPrefs;
}

#pragma mark - Target Action methods

- (IBAction)selectAllMotorKeys:(id)sender {
    // this leaves oldMotorPrefs alone so we can still revert
    self.motorPrefs = nil; // the getter for motorPrefs will re-initialize with all YES
    [self.tableView reloadData];
}

- (IBAction)revertPrefs:(id)sender {
    self.motorPrefs = self.oldMotorPrefs;
    [self.tableView reloadData];
}

- (IBAction)toggleHybrids:(UIBarButtonItem *)sender {
    if (self.showingHybrids){
        // we should hide, so hide the motor manufacturers,and change the button name to "show"
        [self.hybridButton setTitle:NSLocalizedString(@"Show Hybrids", @"Show Hybrids")];
    }else{
        // we should stop hiding them, change the button back to "Hide"
        [self.hybridButton setTitle:NSLocalizedString(@"Hide Hybrids", @"Hide Hybrids")];
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

-(void)viewDidLoad{
    [super viewDidLoad];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        //self.tableView.backgroundColor = [SLCustomUI iPadBackgroundColor];
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_FOR_IPAD_MASTER_VC];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }else{
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:NO animated:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.motorPrefs = [[defaults objectForKey:MOTOR_PREFS_KEY] mutableCopy];
    // notice here that if _motorPrefs is left nil above, the following line will fill both dictionaries with YES values
    self.oldMotorPrefs = [self.motorPrefs copy];
    self.showingHybrids = [defaults boolForKey:SHOWING_HYBRIDS_KEY];
    if (self.showingHybrids){
        [self.hybridButton setTitle:NSLocalizedString(@"Hide Hybrids", @"Hide Hybrids")];
    }else{
        [self.hybridButton setTitle:NSLocalizedString(@"Show Hybrids", @"Show Hybrids")];
    }

    [super viewWillAppear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return NSLocalizedString(@"Motor Manufacturers", @"Motor Manufacturers");
        case 1:
            return NSLocalizedString(@"Motor Diameters", @"Motor Diameters");
        case 2:
            return NSLocalizedString(@"Impulse Classes", @"Impulse Classes");
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
            cellText = [RocketMotor manufacturerNames][indexPath.row];
            cell.imageView.image = [UIImage imageNamed:cellText];
            break;
        case 1:
            cellText = [RocketMotor motorDiameters][indexPath.row];
            cell.imageView.image = nil;
            break;
        case 2:
            cellText = [RocketMotor impulseClasses][indexPath.row];
            cell.imageView.image = nil;
        default:
            break;
    }
    if ([(self.motorPrefs)[cellText] boolValue]){
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }else{
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    cell.textLabel.text = cellText;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return [SLCustomUI headerHeight];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    NSString *headerText;
    switch (section) {
        case 0:
            headerText = NSLocalizedString(@"Motor Manufacturers", @"Motor Manufacturers");
            break;
        case 1:
            headerText = NSLocalizedString(@"Motor Diameters", @"Motor Diameters");
            break;
        case 2:
            headerText = NSLocalizedString(@"Impulse Classes", @"Impulse Classes");
        default:
            break;
    }
    UILabel *headerLabel = [[UILabel alloc] init];
    [headerLabel setTextColor:[SLCustomUI headerTextColor]];
    [headerLabel setBackgroundColor:[UIColor clearColor]];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setText:headerText];
    [headerLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
    
    return headerLabel;
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
        (self.motorPrefs)[motorKey] = @(NO);
    }else{
        // it is not selected, select it and record the selection
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        (self.motorPrefs)[motorKey] = @(YES);
    }
}

#pragma mark - SLMotorPrefsTVC class methods

+ (NSDictionary *)motorKeysAllSelected{
    NSMutableDictionary* buildDict = [NSMutableDictionary dictionaryWithCapacity:64];
    for (NSString *key in [RocketMotor manufacturerNames]) buildDict[key] = @YES;
    for (NSString *key in [RocketMotor motorDiameters]) buildDict[key] = @YES;
    for (NSString *key in [RocketMotor impulseClasses]) buildDict[key] = @YES;
    return [buildDict copy];
}

-(void)dealloc{
    self.motorPrefs = nil;
    self.oldMotorPrefs = nil;
}

-(NSString *)description{
    return @"MotorPrefsTVC";
}

@end
