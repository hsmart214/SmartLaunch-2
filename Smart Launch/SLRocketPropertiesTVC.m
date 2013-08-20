//
//  SLRocketPropertiesTVC.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

/* This controller needs to respond to iCloud updates because it holds a strong Rocket*
 which may change externally.  This is the only place that an existing Rocket * can have
 its name changed.  The current code default behavior in this situation is to delete the
 old instance and save a new one under the new name key.  Upon cancellation, the old 
 instance is restored under the old name, by just leaving without making any changes. */

#import "SLRocketPropertiesTVC.h"
#import "SLMotorConfigurationTVC.h"

#define DELETE_BUTTON_INDEX 2

@interface SLRocketPropertiesTVC ()<UIScrollViewDelegate, UIActionSheetDelegate, UITableViewDelegate, SLMotorConfigurationDataSource, SLMotorConfigurationDelegate>
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *kitNameField;
@property (weak, nonatomic) IBOutlet UITextField *manField;
@property (weak, nonatomic) IBOutlet UITextField *massField;
@property (weak, nonatomic) IBOutlet UITextField *diamField;
@property (weak, nonatomic) IBOutlet UITextField *lenField;
@property (weak, nonatomic) IBOutlet UITextField *cdField;
// These labels set according to the units prefs
@property (weak, nonatomic) IBOutlet UILabel *massUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *diamUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *lenUnitsLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) UIScrollView *scrollView;
@property (nonatomic, weak) UITextField *activeField;
@property (nonatomic, strong) Rocket *oldRocket;
@property (weak, nonatomic) IBOutlet UILabel *calculatedCdLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *calcCdButton;
@property (weak, nonatomic) IBOutlet UILabel *motorConfigLabel;
@property (nonatomic, strong) id iCloudObserver;
@property (nonatomic, strong) NSArray *motorConfiguration;

@end

@implementation SLRocketPropertiesTVC

- (BOOL)isValidRocket{
    BOOL valid = YES;
    valid = valid && ([self.nameField.text length] != 0);
    valid = valid && ([self.massField.text floatValue] > 0.0);
    valid = valid && ([self.diamField.text floatValue] > 0.0);
    //    valid = valid && ([self.motorDiamLabel.text floatValue] > 0);
    valid = valid && ([self.cdField.text floatValue] > 0);
    valid = valid && [self.motorConfiguration count];
    return valid;
}

- (void)updateRocket{
    self.rocket.name = self.nameField.text;
    self.rocket.kitName = self.kitNameField.text;
    self.rocket.manufacturer = self.manField.text;
    self.rocket.mass = [SLUnitsConvertor metricStandardOf:fabs([self.massField.text floatValue]) forKey:MASS_UNIT_KEY];
    self.rocket.diameter = [SLUnitsConvertor metricStandardOf:fabs([self.diamField.text floatValue]) forKey:DIAM_UNIT_KEY];
    self.rocket.length = [SLUnitsConvertor metricStandardOf:fabs([self.lenField.text floatValue]) forKey:LENGTH_UNIT_KEY];
    self.rocket.cd = fabsf([self.cdField.text floatValue]);
    self.rocket.motorConfig = self.motorConfiguration;
    [self.saveButton setEnabled:[self isValidRocket]];
}

- (void)calculateCd{
    float total = 0.0;
    for (NSDictionary *flight in self.rocket.recordedFlights){
        total += [flight[FLIGHT_BEST_CD]floatValue];
    }
    NSInteger numFlights = MAX([self.rocket.recordedFlights count], 1);
    self.calculatedCdLabel.text = [NSString stringWithFormat:@"%1.2f", total/numFlights];
    //enable the "UseCalcCd" button only if there IS a calc Cd to use
    [self.calcCdButton setEnabled:(total != 0.0)];
}

- (IBAction)useCalculatedCd:(UIBarButtonItem *)sender {
    self.cdField.text = self.calculatedCdLabel.text;
    [self updateRocket];
}

- (void)updateDisplay{
    self.nameField.text = self.rocket.name;
    self.kitNameField.text = self.rocket.kitName;
    self.manField.text = self.rocket.manufacturer;
    
    float temp = [SLUnitsConvertor displayUnitsOf:self.rocket.mass forKey:MASS_UNIT_KEY];
    if  (temp > 0.0) self.massField.text = [NSString stringWithFormat:@"%2.2f", temp];
    temp = [SLUnitsConvertor displayUnitsOf:self.rocket.diameter forKey:DIAM_UNIT_KEY];
    if  (temp > 0.0) self.diamField.text = [NSString stringWithFormat:@"%2.2f", temp];
    temp = [SLUnitsConvertor displayUnitsOf:self.rocket.length forKey:LENGTH_UNIT_KEY];
    if  (temp > 0.0) self.lenField.text = [NSString stringWithFormat:@"%2.2f", temp];
    self.cdField.text = [NSString stringWithFormat:@"%2.2f", self.rocket.cd];
    self.motorConfiguration = self.rocket.motorConfig;
    if ([self.motorConfiguration count]) {
        NSUInteger motorTotalCount = 0;
        for (NSDictionary *dict in self.motorConfiguration) {
            motorTotalCount += [dict[MOTOR_COUNT_KEY] integerValue];
        }
        if (motorTotalCount == 1){
            NSUInteger motorSize = [self.motorConfiguration[0][MOTOR_DIAM_KEY] integerValue];
            self.motorConfigLabel.text = [NSString stringWithFormat:@"%d mm", motorSize];
        }else{
            self.motorConfigLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d motors", @"%d motors") , motorTotalCount];
        }
        self.rocket.motorSize = [self.motorConfiguration[0][MOTOR_DIAM_KEY] integerValue];
    }
    [self calculateCd];
    [self.saveButton setEnabled:[self isValidRocket]];
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.tableView.backgroundColor = [SLCustomUI iPadBackgroundColor];
    }else{ // iPhone or iPod
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }
    if (!_rocket){
        _rocket = [[Rocket alloc] init];
        _rocket.motorSize = 6;
    }else {
        self.oldRocket = [self.rocket copy];    // in case we need to delete this Rocket* later
    }
    self.nameField.delegate = self;
    self.kitNameField.delegate = self;
    self.manField.delegate = self;
    self.massField.delegate = self;
    self.diamField.delegate = self;
    self.lenField.delegate = self;
    self.cdField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
    // set up the unit labels based on user preferences
    self.massUnitsLabel.text = [SLUnitsConvertor displayStringForKey:MASS_UNIT_KEY];
    self.lenUnitsLabel.text = [SLUnitsConvertor displayStringForKey:LENGTH_UNIT_KEY];
    self.diamUnitsLabel.text = [SLUnitsConvertor displayStringForKey:DIAM_UNIT_KEY];
    [self updateDisplay];
    
    __weak SLRocketPropertiesTVC *myWeakSelf = self;
    
    self.iCloudObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil queue:nil usingBlock:^(NSNotification *notification){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *changedKeys = [notification userInfo][NSUbiquitousKeyValueStoreChangedKeysKey];
        for (NSString *key in changedKeys) {
            [defaults setObject:[store objectForKey:key] forKey:key];       // right now this can only be the favorite rockets dictionary
        }
        [defaults synchronize];
        Rocket *possiblyChangedRocket = [defaults dictionaryForKey:FAVORITE_ROCKETS_KEY][myWeakSelf.rocket.name];
        if (possiblyChangedRocket){
            myWeakSelf.rocket = possiblyChangedRocket;
        }else{ // somebody deleted or renamed the current rocket, so we will put it back in under the current name to avoid confusion
            NSMutableDictionary *rocketFavorites = [[defaults dictionaryForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
            rocketFavorites[myWeakSelf.rocket.name] = myWeakSelf.rocket;
            [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
            [store setDictionary:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [myWeakSelf updateDisplay];
        });
    }];

}

- (void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self.iCloudObserver];
    self.iCloudObserver = nil;
}

#pragma mark - UITextFieldDelegate methods

- (IBAction)textEditingDidBegin:(UITextField *)sender {
    self.activeField = sender;
}


- (IBAction)textEditingDidEnd:(UITextField *)sender {
    [sender resignFirstResponder];
    self.activeField = nil;
    [self updateRocket];
}

- (IBAction)textEditingDidEndOnExit:(UITextField *)sender {
    [self textEditingDidEnd:sender];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self textEditingDidEnd:textField];
    return YES;
}


#pragma mark - Interface methods

- (IBAction)saveButtonPressed:(UIBarButtonItem *)sender {
    if (self.oldRocket.name && ![self.rocket.name isEqualToString:self.oldRocket.name]){
        [self.delegate SLRocketPropertiesTVC:self deletedRocket:self.oldRocket];
    }
    [self.delegate SLRocketPropertiesTVC:self savedRocket:self.rocket];
    [self.navigationController popViewControllerAnimated:YES];
}


// pop back without saving - no way to undo any saves done to the saved flights, though
- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDelegate method

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - SLSavedFlightsDelegate method

-(void)SLSavedFlightsTVC:(id)sender didUpdateSavedFlights:(NSArray *)savedFlights{
    self.rocket.recordedFlights = [savedFlights copy];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *rocketFavorites = [[defaults dictionaryForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
    rocketFavorites[self.rocket.name] = [self.rocket rocketPropertyList];
    [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    [[NSUbiquitousKeyValueStore defaultStore] setDictionary:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    [defaults synchronize];

    [self calculateCd];
}

#pragma mark - SLMotorConfiguration Datasource and Delegate methods

-(NSArray *)currentMotorConfiguration{
    return self.motorConfiguration;
}

-(void)SLMotorConfigurationTVC:(SLMotorConfigurationTVC *)sender didChangeMotorConfiguration:(NSArray *)configuration{
    self.motorConfiguration = configuration;
    [self updateRocket];
}

#pragma mark - prepareForSegue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"savedFlightsSegue"]){
        //pass on the model for the next table view controller
        [(SLSavedFlightsTVC *)segue.destinationViewController setRocket:self.rocket];
        [(SLSavedFlightsTVC *)segue.destinationViewController setRocketDelegate:self];
    }
    if ([segue.identifier isEqualToString:@"motorConfigurationSegue"]){
        //become the destinations delegate and datasource
        [(SLMotorConfigurationTVC *)segue.destinationViewController setConfigDelegate:self];
        [(SLMotorConfigurationTVC *)segue.destinationViewController setConfigDatasource:self];
    }
}

-(void)dealloc{
    self.rocket = nil;
    self.oldRocket = nil;
    self.motorConfiguration = nil;
    self.iCloudObserver = nil;
}

-(NSString *)description{
    return @"RocketPropertiesTVC";
}

@end
