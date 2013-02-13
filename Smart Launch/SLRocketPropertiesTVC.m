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

#define DELETE_BUTTON_INDEX 2

@interface SLRocketPropertiesTVC ()<UIScrollViewDelegate, UIActionSheetDelegate, UITableViewDelegate>

@property (weak, nonatomic) UIScrollView *scrollView;
@property (nonatomic, weak) UITextField *activeField;
@property (nonatomic, strong) Rocket *oldRocket;
@property (nonatomic, strong, readonly) NSArray *validMotorDiameters;
@property (weak, nonatomic) IBOutlet UILabel *calculatedCdLabel;
@property (weak, nonatomic) IBOutlet UIStepper *motorDiamStepper;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *calcCdButton;
@property (nonatomic, strong) id iCloudObserver;

@end

@implementation SLRocketPropertiesTVC

- (NSArray *)validMotorDiameters{
    return @[@6, @13, @18, @24, @29, @38, @54, @66, @75, @98, @150];
}

- (BOOL)isValidRocket{
    BOOL valid = YES;
    valid = valid && ([self.nameField.text length] != 0);
    valid = valid && ([self.massField.text length] != 0);
    valid = valid && ([self.diamField.text length] != 0);
    valid = valid && ([self.motorDiamLabel.text length] != 0);
    valid = valid && ([self.cdField.text floatValue] > 0);
    return valid;
}

- (void)updateRocket{
    self.rocket.name = self.nameField.text;
    self.rocket.kitName = self.kitNameField.text;
    self.rocket.manufacturer = self.manField.text;
    self.rocket.mass = [SLUnitsConvertor metricStandardOf:
                        @(fabsf([self.massField.text floatValue])) forKey:MASS_UNIT_KEY];
    self.rocket.diameter = [SLUnitsConvertor metricStandardOf:
                            @(fabsf([self.diamField.text floatValue])) forKey:DIAM_UNIT_KEY];
    self.rocket.length = [SLUnitsConvertor metricStandardOf:
                          @(fabsf([self.lenField.text floatValue])) forKey:LENGTH_UNIT_KEY];
    self.rocket.cd = @(fabsf([self.cdField.text floatValue]));
    NSInteger motorDiam = [self.motorDiamLabel.text integerValue];
    self.rocket.motorSize = @(motorDiam);
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
    NSNumber *temp = [SLUnitsConvertor displayUnitsOf:self.rocket.mass forKey:MASS_UNIT_KEY];
    self.massField.text = [NSString stringWithFormat:@"%2.2f", [temp floatValue]];
    temp = [SLUnitsConvertor displayUnitsOf:self.rocket.diameter forKey:DIAM_UNIT_KEY];
    self.diamField.text = [NSString stringWithFormat:@"%2.2f", [temp floatValue]];
    temp = [SLUnitsConvertor displayUnitsOf:self.rocket.length forKey:LENGTH_UNIT_KEY];
    self.lenField.text = [NSString stringWithFormat:@"%2.2f", [temp floatValue]];
    self.cdField.text = [NSString stringWithFormat:@"%2.2f", [self.rocket.cd floatValue]];
    self.motorDiamLabel.text = [NSString stringWithFormat:@"%d", [self.rocket.motorSize integerValue]];
    self.motorDiamStepper.value = [self.rocket.motorSize integerValue];
    [self calculateCd];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    if (!_rocket){
        _rocket = [[Rocket alloc] init];
        self.motorDiamStepper.value = [self.motorDiamStepper minimumValue];
        self.motorDiamLabel.text = [NSString stringWithFormat:@"%1.0f", self.motorDiamStepper.value];
        _rocket.motorSize = @6;
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
    self.motorDiamUnitsLabel.text = [SLUnitsConvertor displayStringForKey:MOTOR_SIZE_UNIT_KEY];
    self.massUnitsLabel.text = [SLUnitsConvertor displayStringForKey:MASS_UNIT_KEY];
    self.lenUnitsLabel.text = [SLUnitsConvertor displayStringForKey:LENGTH_UNIT_KEY];
    self.diamUnitsLabel.text = [SLUnitsConvertor displayStringForKey:DIAM_UNIT_KEY];
    [self updateDisplay];
    
    self.iCloudObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil queue:nil usingBlock:^(NSNotification *notification){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *changedKeys = [notification userInfo][NSUbiquitousKeyValueStoreChangedKeysKey];
        for (NSString *key in changedKeys) {
            [defaults setObject:[store objectForKey:key] forKey:key];       // right now this can only be the favorite rockets dictionary
        }
        [defaults synchronize];
        Rocket *possiblyChangedRocket = [defaults dictionaryForKey:FAVORITE_ROCKETS_KEY][self.rocket.name];
        if (possiblyChangedRocket){
            self.rocket = possiblyChangedRocket;
        }else{ // somebody deleted or renamed the current rocket, so we will put it back in under the current name to avoid confusion
            NSMutableDictionary *rocketFavorites = [[defaults dictionaryForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
            rocketFavorites[self.rocket.name] = self.rocket;
            [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
            [store setDictionary:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateDisplay];
        });
    }];

}

- (void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self.iCloudObserver];
    self.iCloudObserver = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return NO;
        //        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return NO;
    }
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
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - UIStepper method

- (IBAction)motorDiameterChanged:(UIStepper *)sender {
    NSInteger mmt = [self.motorDiamLabel.text integerValue];
    float direction = sender.value - mmt;
    NSInteger newSize = 0;
    if (direction > 0){
        // increment motor size to next larger valid size
        for (int i=0; i < [self.validMotorDiameters count]; i++){
            if ([(self.validMotorDiameters)[i]integerValue] == mmt){
                newSize = [(self.validMotorDiameters)[i+1] integerValue];
                break;
            }
        }
    }else{
        // decrement motor size to next smaller valid size
        for (int i=0; i < [self.validMotorDiameters count]; i++){
            if ([(self.validMotorDiameters)[i]integerValue] == mmt){
                newSize = [(self.validMotorDiameters)[i-1] integerValue];
                break;
            }
        }
    }
    sender.value = newSize;
    self.motorDiamLabel.text = [NSString stringWithFormat:@"%d", newSize];
    [self updateRocket];
}

#pragma mark - Save/Delete/Cancel actions

- (IBAction)saveButtonPressed:(UIBarButtonItem *)sender {
    if (self.oldRocket.name && ![self.rocket.name isEqualToString:self.oldRocket.name]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSMutableDictionary *rocketFavorites = [[defaults dictionaryForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
        [rocketFavorites removeObjectForKey:self.oldRocket.name];
        [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
        // This line takes care of setting the whole dictionary - which has the deleted entry deleted plus the new entry
        [store setDictionary:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    }
    [self.delegate SLRocketPropertiesTVC: self savedRocket:self.rocket];
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

#pragma mark - prepareForSegue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"savedFlightsSegue"]){
        //pass on the model for the next table view controller
        [(SLSavedFlightsTVC *)segue.destinationViewController setRocket:self.rocket];
        [(SLSavedFlightsTVC *)segue.destinationViewController setRocketDelegate:self];
    }
}

-(void)dealloc{
    self.rocket = nil;
    self.oldRocket = nil;
}

@end
