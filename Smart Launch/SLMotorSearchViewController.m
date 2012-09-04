//
//  SLMotorSearchViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import "SLMotorSearchViewController.h"
#import "SLMotorTableViewController.h"

@interface SLMotorSearchViewController () <UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, strong) NSArray *impulseClasses;
@property (nonatomic, strong) NSArray *motorDiameters;
@end

@implementation SLMotorSearchViewController

@synthesize search1Control;
@synthesize search2Control;
@synthesize pickerView;
@synthesize manufacturerNames = _manufacturerNames;
@synthesize impulseClasses = _impulseClasses;
@synthesize motorDiameters = _motorDiameters;
@synthesize allMotors = _allMotors;
@synthesize delegate = _delegate;

NSInteger sortFunction(id md1, id md2, void *context){
    NSString *first = [(NSDictionary *)md1 objectForKey:NAME_KEY];
    NSString *second = [(NSDictionary *)md2 objectForKey:NAME_KEY];
    if ([first characterAtIndex:0] > [second characterAtIndex:0]) return NSOrderedDescending;
    if ([first characterAtIndex:0] < [second characterAtIndex:0]) return NSOrderedAscending;
    // at this point we know the impulse class is the SAME, so sort by the average thrust
    NSInteger thrust1 = [[first substringFromIndex:1] integerValue];
    NSInteger thrust2 = [[second substringFromIndex:1] integerValue];
    if (thrust1 > thrust2) return NSOrderedDescending;
    if (thrust1 < thrust2) return NSOrderedAscending;
    return NSOrderedSame;
}

- (NSArray *)allMotors{
    if (!_allMotors){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _allMotors = [defaults objectForKey:ALL_MOTORS_KEY];
        if (_allMotors) return _allMotors;
        NSMutableArray *build = [NSMutableArray array];
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSURL *motorsURL = [mainBundle URLForResource:@"motors" withExtension:@"txt"];
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
                if ([[textLines objectAtIndex:0] characterAtIndex:0]== ';'){
                    [textLines removeObjectAtIndex:0];
                    if ([textLines count] == 0){
                        header = nil;
                        break;
                    }
                }else{    // and grab the header line
                    header = [textLines objectAtIndex:0];
                    [textLines removeObjectAtIndex:0];
                    break;
                }
            }
            if (!header) break;
            NSArray *chunks = [header componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [motorData setValue:[chunks objectAtIndex:0] forKey:NAME_KEY];
            [motorData setValue:[chunks objectAtIndex:1] forKey:MOTOR_DIAM_KEY];
            [motorData setValue:[chunks objectAtIndex:2] forKey:MOTOR_LENGTH_KEY];
            [motorData setValue:[chunks objectAtIndex:3] forKey:DELAYS_KEY];
            [motorData setValue:[chunks objectAtIndex:4] forKey:PROP_MASS_KEY];
            [motorData setValue:[chunks objectAtIndex:5] forKey:MOTOR_MASS_KEY];
            [motorData setValue:[self.manufacturerNames objectForKey:[chunks objectAtIndex:6]] forKey:MAN_KEY];
            // NSLog(@"%@", [chunks objectAtIndex:0]);
            // figure out the impulse class from the motor name in the header line
            
            NSString *mname = [chunks objectAtIndex:0];
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
                chunks = [[textLines objectAtIndex:0] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                chunks = [NSArray arrayWithObjects:[chunks objectAtIndex:0], [chunks lastObject], nil];
                [times addObject:[NSNumber numberWithFloat:[[chunks objectAtIndex:0] floatValue]]];
                [thrusts addObject:[NSNumber numberWithFloat:[[chunks objectAtIndex:1] floatValue]]];
                [textLines removeObjectAtIndex:0];
                if ([[chunks objectAtIndex:1] floatValue] == 0.0) break;
            }
            [motorData setValue:times forKey:TIME_KEY];
            [motorData setValue:thrusts forKey:THRUST_KEY];
            [build addObject:motorData];
        }
        _allMotors = [[NSArray arrayWithArray:build] sortedArrayUsingFunction:sortFunction context:NULL];
        [defaults setObject:_allMotors forKey:ALL_MOTORS_KEY];
        [defaults synchronize];
        // NSLog(@"Loaded %d motors", [build count]);
    }
    return _allMotors;
}

- (NSDictionary *)manufacturerNames{
    if (!_manufacturerNames){
        _manufacturerNames = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"AMW Pro-X", @"AMW_ProX",
                              @"Aerotech RMS", @"A-RMS",
                              @"Aerotech", @"A",
                              @"Aerotech Hybrid", @"ATH",
                              @"Animal Motor Works", @"AMW",
                              @"Apogee", @"Apogee",
                              @"Cesaroni", @"CTI",
                              @"Contrail", @"Contrail_Rockets",
                              @"Ellis Mountain", @"Ellis",
                              @"Estes", @"Estes",
                              @"Gorilla", @"Gorilla_Rocket_Motors",
                              @"Hypertek", @"HT",
                              @"Kosdon by Aerotech", @"KA",
                              @"Kosdon", @"KOS-TRM",
                              @"Loki Research", @"Loki",
                              @"Public Missiles Ltd", @"PML",
                              @"Propulsion Polymers", @"Propul",
                              @"Quest", @"Q",
                              @"RATTworks", @"RATT", 
                              @"RoadRunner", @"RR",
                              @"Sky Ripper", @"SkyRip",
                              @"West Coast Hybrids", @"WCoast", nil];
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


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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
        self.search1Control.selectedSegmentIndex = [[lastMotorSearch objectForKey:MOTOR_SEARCH_1_KEY] intValue];
        self.search2Control.selectedSegmentIndex = [[lastMotorSearch objectForKey:MOTOR_SEARCH_2_KEY] intValue];
        [self.pickerView selectRow:[[lastMotorSearch objectForKey:MOTOR_SEARCH_PICKER_INDEX] intValue] inComponent:0 animated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewDidUnload
{
    [self setSearch1Control:nil];
    [self setSearch2Control:nil];
    [self setPickerView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UIPickerView Delegate and Datasource methods


// methods to implement the picker view
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
    switch (self.search1Control.selectedSegmentIndex) {
        case 0:  // Motor manufacturer selected
            return [self.manufacturerNames count];
            break;
        case 1:  // Impulse Class selected
            return [self.impulseClasses count];
            break;
        case 2:  // Motor Diameter selected
            return [self.motorDiameters count];
        default:
            break;
    }
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES];
    NSArray *sorts = [NSArray arrayWithObject:sort];
    switch (self.search1Control.selectedSegmentIndex) {
        case 0:  // Motor manufacturer selected
            return [[[self.manufacturerNames allValues] sortedArrayUsingDescriptors:sorts] objectAtIndex:row];
            break;
        case 1:  // Impulse Class selected
            return [self.impulseClasses objectAtIndex:row];
            break;
        case 2:  // Motor Diameter selected
            return [self.motorDiameters objectAtIndex:row];
        default:
            break;
    }
    return @"Error";
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [thePickerView selectRow:row inComponent:component animated:YES];
}

#pragma mark Target Action methods

- (IBAction)search1ValueChanged:(UISegmentedControl *)sender {
    [self.pickerView reloadAllComponents];
}
- (IBAction)search2ValueChanged:(UISegmentedControl *)sender {
}

#pragma mark prepareForSegue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"motorSearchSegue"]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *lastMotorSearch = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:[self.pickerView selectedRowInComponent:0]], MOTOR_SEARCH_PICKER_INDEX,
                                         [NSNumber numberWithInt:self.search1Control.selectedSegmentIndex], MOTOR_SEARCH_1_KEY,
                                         [NSNumber numberWithInt:self.search2Control.selectedSegmentIndex], MOTOR_SEARCH_2_KEY, nil];
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
                    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES];
                    NSArray *sorts = [NSArray arrayWithObject:sort];
                    NSString *manuf = [[[self.manufacturerNames allValues] sortedArrayUsingDescriptors:sorts] objectAtIndex:selectedRow];
                    for (NSDictionary *motorDict in self.allMotors){
                        if ([[motorDict objectForKey:MAN_KEY] isEqualToString:manuf]){
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
                    NSString *impulseClass = [self.impulseClasses objectAtIndex:selectedRow];
                    for (NSDictionary *motorDict in self.allMotors){
                        if ([[motorDict objectForKey:IMPULSE_KEY] isEqualToString:impulseClass]){
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
                    NSString *requestedDiameter = [self.motorDiameters objectAtIndex:selectedRow];
                    requestedDiameter = [requestedDiameter substringToIndex:[requestedDiameter length]-2];
                    for (NSDictionary *motorDict in self.allMotors){
                        if ([[motorDict objectForKey:MOTOR_DIAM_KEY] isEqualToString:requestedDiameter]){
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
                    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES];
                    NSArray *sorts = [NSArray arrayWithObject:sort];
                    for (NSString *man in [[self.manufacturerNames allValues] sortedArrayUsingDescriptors:sorts]){
                        NSMutableArray *motorsForMan = [NSMutableArray array];
                        for (NSDictionary *motorDict in searchResult){
                            if ([[motorDict objectForKey:MAN_KEY] isEqualToString:man]){
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
                    for (NSString *imp in self.impulseClasses){
                        NSMutableArray *motorsForImpulse = [NSMutableArray array];
                        for (NSDictionary *motorDict in searchResult){
                            if ([[motorDict objectForKey:IMPULSE_KEY] isEqualToString:imp]){
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
                    for (NSString *diam in self.motorDiameters){
                        NSString *testDiam = [diam substringToIndex:[diam length]-2];
                        NSMutableArray *motorsForDiam = [NSMutableArray array];
                        for (NSDictionary *motorDict in searchResult){
                            if ([[motorDict objectForKey:MOTOR_DIAM_KEY] isEqualToString:testDiam]){
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