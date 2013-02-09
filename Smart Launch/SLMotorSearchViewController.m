//
//  SLMotorSearchViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLMotorSearchViewController.h"
#import "SLMotorTableViewController.h"
#import "SLMotorPrefsTVC.h"

@interface SLMotorSearchViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate>
@property (nonatomic, strong) NSArray *impulseClasses;
@property (nonatomic, strong) NSArray *motorDiameters;
@property (nonatomic, strong) NSDictionary *motorKeyPrefs; // Dict of NSNumber BOOLs = should show motors with this key?

@property (nonatomic, strong) NSArray *preferredManufacturers;
@property (nonatomic, strong) NSArray *preferredImpulseClasses;
@property (nonatomic, strong) NSArray *preferredMotorDiameters;
@property (nonatomic, strong) NSArray *restrictedMotorDiamPrefs;

@property (weak, nonatomic) IBOutlet UISegmentedControl *restrictMotorDiametersSegmentedControl;
@end

@implementation SLMotorSearchViewController

NSInteger sortFunction(id md1, id md2, void *context){
    NSString *first = ((NSDictionary *)md1)[NAME_KEY];
    NSString *second = ((NSDictionary *)md2)[NAME_KEY];
    if ([first characterAtIndex:0] > [second characterAtIndex:0]) return NSOrderedDescending;
    if ([first characterAtIndex:0] < [second characterAtIndex:0]) return NSOrderedAscending;
    // at this point we know the impulse class is the SAME, so sort by the average thrust
    NSInteger thrust1 = [[first substringFromIndex:1] integerValue];
    NSInteger thrust2 = [[second substringFromIndex:1] integerValue];
    if (thrust1 > thrust2) return NSOrderedDescending;
    if (thrust1 < thrust2) return NSOrderedAscending;
    return NSOrderedSame;
}

- (NSDictionary *)motorKeyPrefs{
    // note that these preferences cannot change while this controller is alive
    if (!_motorKeyPrefs){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _motorKeyPrefs = [defaults objectForKey:MOTOR_PREFS_KEY];
        if (!_motorKeyPrefs) _motorKeyPrefs = [SLMotorPrefsTVC motorKeysAllSelected];
    }
    return _motorKeyPrefs;
}

- (NSArray *)allMotors{
    if (!_allMotors){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger currentMotorsVersion = [defaults integerForKey:MOTOR_FILE_VERSION_KEY];
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSInteger bundleMotorVersion = [[NSString stringWithContentsOfURL:[mainBundle URLForResource:MOTOR_VERSION_FILENAME withExtension:@"txt"] encoding:NSUTF8StringEncoding error:nil]integerValue];
        NSURL *cacheURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *motorFileURL = [cacheURL URLByAppendingPathComponent:MOTOR_CACHE_FILENAME];
        if ([[NSFileManager defaultManager]fileExistsAtPath:[motorFileURL path]]){
            _allMotors = [NSArray arrayWithContentsOfURL:motorFileURL];
            return _allMotors;
        }
        NSMutableArray *build = [NSMutableArray array];
        
        NSURL *motorsURL = [mainBundle URLForResource:@"motors" withExtension:@"txt"];
        if (currentMotorsVersion > bundleMotorVersion){
            NSURL *docURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            motorsURL = [docURL URLByAppendingPathComponent:MOTOR_DATA_FILENAME];
        }
        NSError *err;
        NSString *motors = [NSString stringWithContentsOfURL:motorsURL encoding:NSUTF8StringEncoding error:&err];
        if (err){
            NSLog(@"%@, %@", @"Error reading motors.txt",[err debugDescription]);
        }
        NSMutableArray *textLines = [NSMutableArray arrayWithArray:[motors componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]]];
        while ([textLines count] > 0) {
            NSMutableDictionary *motorData = [NSMutableDictionary dictionary];
            NSString *header;
            while (true){ // remove all of the comment lines
                if ([textLines[0] characterAtIndex:0]== ';'){
                    [textLines removeObjectAtIndex:0];
                    if ([textLines count] == 0){
                        header = nil;
                        break;
                    }
                }else{    // and grab the header line
                    header = textLines[0];
                    [textLines removeObjectAtIndex:0];
                    break;
                }
            }
            if (!header) break;
            NSArray *chunks = [header componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [motorData setValue:chunks[0] forKey:NAME_KEY];
            [motorData setValue:chunks[1] forKey:MOTOR_DIAM_KEY];
            [motorData setValue:chunks[2] forKey:MOTOR_LENGTH_KEY];
            [motorData setValue:chunks[3] forKey:DELAYS_KEY];
            [motorData setValue:chunks[4] forKey:PROP_MASS_KEY];
            [motorData setValue:chunks[5] forKey:MOTOR_MASS_KEY];
            [motorData setValue:(self.manufacturerNames)[chunks[6]] forKey:MAN_KEY];
            // figure out the impulse class from the motor name in the header line
            
            NSString *mname = chunks[0];
            if ([[mname substringToIndex:2] isEqualToString:@"MM"]) {
                [motorData setValue:@"1/8A" forKey:IMPULSE_KEY];
            }
            else if ([[mname substringToIndex:2] isEqualToString:@"1/"]) {
                [motorData setValue:[mname substringToIndex:4] forKey:IMPULSE_KEY];
            }
            else {
                [motorData setValue:[mname substringToIndex:1] forKey:IMPULSE_KEY];
            }
            // after the header the lines are all time / thrust pairs until the thrust is zero
            NSMutableArray *times = [NSMutableArray array];
            NSMutableArray *thrusts = [NSMutableArray array];
            while (true){
                chunks = [textLines[0] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                chunks = @[chunks[0], [chunks lastObject]];
                [times addObject:@([chunks[0] floatValue])];
                [thrusts addObject:@([chunks[1] floatValue])];
                [textLines removeObjectAtIndex:0];
                if ([chunks[1] floatValue] == 0.0) break;
            }
            [motorData setValue:times forKey:TIME_KEY];
            [motorData setValue:thrusts forKey:THRUST_KEY];
            
            //check to see if any of the keys are exluded by the user's preference
            // first add "mm" to the motor diameter string
            NSString *motorDiamKey = (NSString *)[motorData[MOTOR_DIAM_KEY] stringByAppendingString:@"mm"];
            if ([(self.motorKeyPrefs)[motorData[MAN_KEY]] boolValue] &&
                [(self.motorKeyPrefs)[motorData[IMPULSE_KEY]] boolValue] &&
                [(self.motorKeyPrefs)[motorDiamKey] boolValue])
            {
                [build addObject:motorData]; // if not excluded, add it to the growing list off allMotors
            }
        }
        _allMotors = [[NSArray arrayWithArray:build] sortedArrayUsingFunction:sortFunction context:NULL];
        [_allMotors writeToURL:motorFileURL atomically:YES];
        //NSLog(@"Loaded %d motors.",[_allMotors count]);
    }
    return _allMotors;
}

- (NSDictionary *)manufacturerNames{
    if (!_manufacturerNames){
        _manufacturerNames = @{@"AMW_ProX": @"AMW Pro-X",
                              @"A-RMS": @"Aerotech RMS",
                              @"A": @"Aerotech",
                              @"ATH": @"Aerotech Hybrid",
                              @"AMW": @"Animal Motor Works",
                              @"Apogee": @"Apogee",
                              @"CTI": @"Cesaroni",
                              @"Contrail_Rockets": @"Contrail Rockets",
                              @"Ellis": @"Ellis Mountain",
                              @"Estes": @"Estes",
                              @"Gorilla_Rocket_Motors": @"Gorilla Rocket Motors",
                              @"HT": @"Hypertek",
                              @"KA": @"Kosdon by Aerotech",
                              @"KOS-TRM": @"Kosdon",
                              @"Loki": @"Loki Research",
                              @"PML": @"Public Missiles Ltd",
                              @"Propul": @"Propulsion Polymers",
                              @"Q": @"Quest",
                              @"RATT": @"RATTworks", 
                              @"RR": @"RoadRunner",
                              @"SkyRip": @"Sky Ripper",
                              @"WCoast": @"West Coast Hybrids"};
    }
    return _manufacturerNames;
}

- (NSArray *)impulseClasses{
    return [RocketMotor impulseClasses];
}

- (NSArray  *)motorDiameters{
    return [RocketMotor motorDiameters];
}

- (NSArray *)preferredManufacturers{
    // note that these preferences cannot change while this controller is alive
    if (!_preferredManufacturers){
        NSMutableArray *prefMan = [NSMutableArray arrayWithCapacity:32];
        for (NSString *key in [RocketMotor manufacturerNames]){
            if ([(self.motorKeyPrefs)[key] boolValue]) [prefMan addObject:key];
        }
        _preferredManufacturers = [prefMan copy];
    }
    return _preferredManufacturers;
}

- (NSArray *)preferredImpulseClasses{
    // note that these preferences cannot change while this controller is alive
    if (!_preferredImpulseClasses){
        NSMutableArray *prefICs = [NSMutableArray arrayWithCapacity:32];
        for (NSString *key in [RocketMotor impulseClasses]){
            if ([(self.motorKeyPrefs)[key] boolValue]) [prefICs addObject:key];
        }
        _preferredImpulseClasses = [prefICs copy];
    }
    return _preferredImpulseClasses;
}

- (NSArray *)preferredMotorDiameters{
    // note that these preferences can change while this controller is alive if the user forces a rocket
    // with a deselected MMT size
    if (!_preferredMotorDiameters){
        NSMutableArray *prefDiams = [NSMutableArray arrayWithCapacity:16];
        for (NSString *key in [RocketMotor motorDiameters]){
            if ([(self.motorKeyPrefs)[key] boolValue]) [prefDiams addObject:key];
        }
        _preferredMotorDiameters = [prefDiams copy];
    }
    return _preferredMotorDiameters;
}

- (BOOL)preferredMotorDiametersContainsDiameter:(NSString *)diamStringWithMM{
    BOOL contained = NO;
    for (NSString *diam in self.preferredMotorDiameters){
        contained = contained || [diam isEqualToString:diamStringWithMM];
        if (contained) break;
    }
    return contained;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    NSString *backgroundFileName = [[NSBundle mainBundle] pathForResource: BACKGROUND_IMAGE_FILENAME ofType:@"png"];
    UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:backgroundFileName];
    [backgroundView setImage:backgroundImage];
    [self.view insertSubview:backgroundView atIndex:0];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    [self.pickerView reloadAllComponents];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *lastMotorSearch = [defaults objectForKey:LAST_MOTOR_SEARCH_KEY];
    if (lastMotorSearch) {
        self.search1Control.selectedSegmentIndex = [lastMotorSearch[MOTOR_SEARCH_1_KEY] intValue];
        self.search2Control.selectedSegmentIndex = [lastMotorSearch[MOTOR_SEARCH_2_KEY] intValue];
        [self.pickerView selectRow:[lastMotorSearch[MOTOR_SEARCH_PICKER_INDEX] intValue] inComponent:0 animated:YES];
        self.restrictMotorDiametersSegmentedControl.selectedSegmentIndex = [lastMotorSearch[MOTOR_SEARCH_MATCH_DIAM_KEY]integerValue];
    }else{
        self.search1Control.selectedSegmentIndex = 0; // Brand
        self.search2Control.selectedSegmentIndex = 1; // Class
        NSInteger row = [self.preferredManufacturers indexOfObject:@"Estes"];
        if (row != NSNotFound){
            [self.pickerView selectRow:row inComponent:0 animated:YES];
        }else{
            [self.pickerView selectRow:0 inComponent:0 animated:YES];
        }
        self.restrictMotorDiametersSegmentedControl.selectedSegmentIndex = 1;   // MMT or less
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self motorDiameterRestrictionChanged:self.restrictMotorDiametersSegmentedControl];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.preferredImpulseClasses = nil;
    self.preferredManufacturers = nil;
    self.preferredMotorDiameters = nil;
}

- (void)didReceiveMemoryWarning{
    self.allMotors = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIPickerView Delegate and Datasource methods


// methods to implement the picker view
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
    switch (self.search1Control.selectedSegmentIndex) {
        case 0:  // Motor manufacturer selected
            return [self.preferredManufacturers count];
            break;
        case 1:  // Impulse Class selected
            return [self.preferredImpulseClasses count];
            break;
        case 2:  // Motor Diameter selected
            if (self.restrictedMotorDiamPrefs) return [self.restrictedMotorDiamPrefs count];
            return [self.preferredMotorDiameters count];
        default:
            break;
    }
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch (self.search1Control.selectedSegmentIndex) {
        case 0:  // Motor manufacturer selected
            return (self.preferredManufacturers)[row];
            break;
        case 1:  // Impulse Class selected
            return (self.preferredImpulseClasses)[row];
            break;
        case 2:  // Motor Diameter selected
            if (self.restrictedMotorDiamPrefs) return (self.restrictedMotorDiamPrefs)[row];
            return (self.preferredMotorDiameters)[row];
        default:
            break;
    }
    return @"Error";
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [thePickerView selectRow:row inComponent:component animated:YES];
}

#pragma mark - UIActionSheetDelegate methods

- (void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == [actionSheet destructiveButtonIndex]){
        // this is the one that *does* change the settings to accomodate the current MMT size
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *motorPrefs = [self.motorKeyPrefs mutableCopy];
        NSString *motorMM = [NSString stringWithFormat:@"%@mm", [self.rocketMotorMountDiameter description]];
        motorPrefs[motorMM] = @YES;
        [defaults setObject:motorPrefs forKey:MOTOR_PREFS_KEY];
        [defaults synchronize];
        _motorKeyPrefs = [motorPrefs copy];
        _preferredMotorDiameters = nil;
        _allMotors = nil;   // this forces a recalculation of allMotors
        [self.pickerView reloadAllComponents];
    }else{
        // do not change the preferences (likely to result in a blank screen of motors down the line)
    }
}

#pragma mark - Target Action methods

- (IBAction)search1ValueChanged:(UISegmentedControl *)sender {
    [self motorDiameterRestrictionChanged:self.restrictMotorDiametersSegmentedControl];
    [self.pickerView reloadAllComponents];
}

- (IBAction)motorDiameterRestrictionChanged:(UISegmentedControl *)sender {
    NSString *currMMT = [[self.rocketMotorMountDiameter description] stringByAppendingString:@"mm"];
    NSString *prevDiam = @"6mm";
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.restrictedMotorDiamPrefs = nil;
            [self.pickerView reloadAllComponents];
            return;
        case 1:
            // motor mount size or less
            if ([self.rocketMotorMountDiameter intValue] == 6){
                self.restrictedMotorDiamPrefs = @[@"6mm"];
                [self.pickerView reloadAllComponents];
                return;
            }

            for (NSString *diam in [RocketMotor motorDiameters]){
                if ([diam intValue] == [self.rocketMotorMountDiameter intValue]){
                    self.restrictedMotorDiamPrefs = @[prevDiam, diam];
                    if ([prevDiam isEqualToString:diam]) self.restrictedMotorDiamPrefs = @[diam];
                    [self.pickerView reloadAllComponents];
                    return;
                }else{
                    prevDiam = [diam copy]; // next iteration in for loop
                }
            }
            break;
        case 2:
            // motor mount exact match only
            self.restrictedMotorDiamPrefs = @[currMMT];
            if (![self preferredMotorDiametersContainsDiameter:currMMT]){
                NSString *sheetTitle = [NSString stringWithFormat:@"Would you like to show the %@ motors?", currMMT];
                UIActionSheet *diameterSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle delegate:self cancelButtonTitle:@"No" destructiveButtonTitle:@"Yes, show this size." otherButtonTitles: nil];
                [diameterSheet showFromToolbar:self.navigationController.toolbar];
            }
        default:
            break;
    }
    [self.pickerView reloadAllComponents];
}

- (NSArray *)currentlyAllowedMotorDiametersWithMM{
    // returns an array on NSStrings with the "mm" after the motor size
    if (!self.restrictedMotorDiamPrefs) return self.preferredMotorDiameters;
    NSMutableArray *allowed  = [NSMutableArray arrayWithCapacity:2];
    for (NSString *diamMM in self.restrictedMotorDiamPrefs){
        if ([self preferredMotorDiametersContainsDiameter:diamMM]){
            [allowed addObject:diamMM];
        }
    }
    return [allowed copy];
}


#pragma mark prepareForSegue

- (BOOL)restrictionsAllowMotorDict:(NSDictionary *)motorDict{
    BOOL allowed = NO;
    NSString *motorMM = [[motorDict[MOTOR_DIAM_KEY] description] stringByAppendingString:@"mm"];
    if (self.restrictedMotorDiamPrefs){
        for (NSString *testMM in self.restrictedMotorDiamPrefs){
            allowed = allowed || [testMM isEqualToString:motorMM];
        }
    }else{ // only the preferred motors matter
        allowed = [self preferredMotorDiametersContainsDiameter:motorMM];
    }
    return allowed;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"motorSearchSegue"]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *lastMotorSearch = @{MOTOR_SEARCH_PICKER_INDEX: @([self.pickerView selectedRowInComponent:0]),
                                        MOTOR_SEARCH_1_KEY: @(self.search1Control.selectedSegmentIndex),
                                        MOTOR_SEARCH_2_KEY: @(self.search2Control.selectedSegmentIndex),
                                        MOTOR_SEARCH_MATCH_DIAM_KEY: @(self.restrictMotorDiametersSegmentedControl.selectedSegmentIndex)};
        [defaults setObject:lastMotorSearch forKey:LAST_MOTOR_SEARCH_KEY];
        [defaults synchronize];
        [[segue destinationViewController]setDelegate:self.delegate];
        NSMutableArray *searchResult = [NSMutableArray array];
        switch (self.search1Control.selectedSegmentIndex) {
            case 0:  // Motor manufacturer selected
            {
                NSInteger selectedRow = [self.pickerView selectedRowInComponent:0];
                if (selectedRow == -1){ // no row was selected, so include all manufacturers
                    
                }else{                  // only include the one manufacturer selected
                    NSMutableArray *motorsByManufacturer = [NSMutableArray array];
                    NSString *manuf = (self.preferredManufacturers)[selectedRow];
                    for (NSDictionary *motorDict in self.allMotors){
                        if ([motorDict[MAN_KEY] isEqualToString:manuf] && [self restrictionsAllowMotorDict:motorDict]){
                            [motorsByManufacturer addObject:motorDict];
                        }
                    }
                    searchResult = motorsByManufacturer;
                }
                break;
            }
            case 1:  // Impulse Class selected
            {
                NSInteger selectedRow = [self.pickerView selectedRowInComponent:0];
                if (selectedRow == -1){ // no row was selected, so include all impulses
                    
                }else{                  // only include the one impulse class selected
                    NSMutableArray *motorsByImpulseClass = [NSMutableArray array];
                    NSString *impulseClass = (self.preferredImpulseClasses)[selectedRow];
                    for (NSDictionary *motorDict in self.allMotors){
                        if ([motorDict[IMPULSE_KEY] isEqualToString:impulseClass] && [self restrictionsAllowMotorDict:motorDict]){
                            [motorsByImpulseClass addObject:motorDict];
                        }
                    }
                    searchResult = motorsByImpulseClass;
                }
                break;  
            }
            case 2:  // Motor Diameter selected
            {
                NSInteger selectedRow = [self.pickerView selectedRowInComponent:0];
                if (selectedRow == -1){ // no row was selected, so include all diameters
                    
                }else{                  // only include the one diameter selected
                    NSMutableArray *motorsByDiameter = [NSMutableArray array];
                    NSString *requestedDiameter;
                    if (self.restrictedMotorDiamPrefs){
                        requestedDiameter = (self.restrictedMotorDiamPrefs)[selectedRow];
                    }else{
                        requestedDiameter = (self.preferredMotorDiameters)[selectedRow];
                    }
                    requestedDiameter = [requestedDiameter substringToIndex:[requestedDiameter length]-2]; // take off the "mm"
                    for (NSDictionary *motorDict in self.allMotors){
                        if ([motorDict[MOTOR_DIAM_KEY] isEqualToString:requestedDiameter]){
                            [motorsByDiameter addObject:motorDict];
                        }
                    }
                    searchResult = motorsByDiameter;
                }
            }
            default:
                break;
        }
        NSMutableArray *sortedResults = [NSMutableArray array];
        if (self.search1Control.selectedSegmentIndex != self.search2Control.selectedSegmentIndex){
            switch (self.search2Control.selectedSegmentIndex){
                case 0:{    // sort the results by manufacturer, each into its own array
                    [(SLMotorTableViewController *)segue.destinationViewController setSectionKey:MAN_KEY];
                    for (NSString *man in self.preferredManufacturers){
                        NSMutableArray *motorsForMan = [NSMutableArray array];
                        for (NSDictionary *motorDict in searchResult){
                            if ([motorDict[MAN_KEY] isEqualToString:man]){
                                [motorsForMan addObject:motorDict];
                            }
                        }
                        // don't add an empty dictionary
                        if ([motorsForMan count]) [sortedResults addObject:motorsForMan];
                    }
                    break;
                }
                case 1:{    // sort the results by impulse class
                    [(SLMotorTableViewController *)segue.destinationViewController setSectionKey:IMPULSE_KEY];
                    for (NSString *imp in self.preferredImpulseClasses){
                        NSMutableArray *motorsForImpulse = [NSMutableArray array];
                        for (NSDictionary *motorDict in searchResult){
                            if ([motorDict[IMPULSE_KEY] isEqualToString:imp]){
                                [motorsForImpulse addObject:motorDict];
                            }
                        }
                        // don't add an empty dictionary
                        if ([motorsForImpulse count]) [sortedResults addObject:motorsForImpulse];
                    }
                    break;
                }
                case 2:{    // sort the results by diameter
                    [(SLMotorTableViewController *)segue.destinationViewController setSectionKey:MOTOR_DIAM_KEY];
                    NSArray *motorsWithCertainDiameters;
                    if (self.restrictedMotorDiamPrefs){
                        motorsWithCertainDiameters = self.restrictedMotorDiamPrefs;
                    }else{
                        motorsWithCertainDiameters = self.preferredMotorDiameters;
                    }
                    for (NSString *diam in motorsWithCertainDiameters){
                        NSString *testDiam = [diam substringToIndex:[diam length]-2];
                        NSMutableArray *motorsForDiam = [NSMutableArray array];
                        for (NSDictionary *motorDict in searchResult){
                            if ([motorDict[MOTOR_DIAM_KEY] isEqualToString:testDiam]){
                                [motorsForDiam addObject:motorDict];
                            }
                        }
                        // don't add an empty dictionary
                        if ([motorsForDiam count]) [sortedResults addObject:motorsForDiam];
                    }
                }
                default:
                    break;
            }
        }else {
            NSString *sortKey;
            switch (self.search1Control.selectedSegmentIndex) {
                case 0:
                    sortKey = MAN_KEY;
                    break;
                case 1:
                    sortKey = IMPULSE_KEY;
                    break;
                case 2:
                    sortKey = MOTOR_DIAM_KEY;
                default:
                    break;
            }
            [(SLMotorTableViewController *)segue.destinationViewController setSectionKey:sortKey];
            [sortedResults addObject:searchResult];
        }
        [(SLMotorTableViewController *)segue.destinationViewController setMotors:sortedResults];
    }
}

@end