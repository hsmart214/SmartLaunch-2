//
//  SLSaveFlightDataTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 1/13/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLSaveFlightDataTVC.h"
#import "SLUnitsConvertor.h"

@interface SLSaveFlightDataTVC ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *rocketName;
@property (weak, nonatomic) IBOutlet UIImageView *motorManufacturerLogo;
@property (weak, nonatomic) IBOutlet UILabel *motorName;
@property (weak, nonatomic) IBOutlet UILabel *launchAngleLabel;
@property (weak, nonatomic) IBOutlet UITextField *cdEstimateField;
@property (weak, nonatomic) IBOutlet UITextField *actualAltitudeField;
@property (weak, nonatomic) IBOutlet UILabel *altUnitsLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *calculationProgressIndicator;
@property (weak, nonatomic) IBOutlet UILabel *cdLabel;
@property (weak, nonatomic) IBOutlet UILabel *windDirectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *altitudeLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) id iCloudObserver;

@end

@implementation SLSaveFlightDataTVC

- (IBAction)cancelFlightSaving:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveFlightData:(UIBarButtonItem *)sender {
    float cd = [self.cdLabel.text floatValue];
    float alt = [self.actualAltitudeField.text floatValue];
    NSMutableDictionary *newFlightData = [self.flightData mutableCopy];
    newFlightData[FLIGHT_BEST_CD] = @(cd);
    newFlightData[FLIGHT_ALTITUDE_KEY] = @([SLUnitsConvertor metricStandardOf:alt forKey:ALT_UNIT_KEY]);
    //fetch the default rockets
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSMutableDictionary *rocketPlists = [[defaults objectForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
    if (!rocketPlists) rocketPlists = [NSMutableDictionary dictionary];
    //add the flight data
    [self.rocket addFlight:newFlightData];
    //put the rocket back in the dictionary
    rocketPlists[self.rocket.name] = [self.rocket rocketPropertyList];
    //put the dictionary back into the favorites store
    [defaults setObject:rocketPlists forKey:FAVORITE_ROCKETS_KEY];
    [store setDictionary:rocketPlists forKey:FAVORITE_ROCKETS_KEY];
    [defaults synchronize];
    
    [self.delegate sender:self didChangeRocket:self.rocket];
    //[self.delegate SLRocketPropertiesTVC:(id)self savedRocket:self.rocket];
    
    [self.navigationController popViewControllerAnimated:YES];
}



- (IBAction)calculateNewCd:(id)sender {
    if ([self.actualAltitudeField.text floatValue] == 0.0) return;
    float initialGuess = [self.cdEstimateField.text floatValue];
    __block Rocket *tempRocket = [self.rocket copy];
    [tempRocket replaceMotorLoadOutWithLoadOut:self.physicsModel.rocket.motorLoadoutPlist];
    tempRocket.cd = initialGuess;
    self.physicsModel.rocket = tempRocket;
    
    float actualAlt = [self.actualAltitudeField.text floatValue];
    actualAlt = [SLUnitsConvertor metricStandardOf:actualAlt forKey:ALT_UNIT_KEY];
    //need to do this in a separate thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            float prog = 1.0/(NEWTON_RAPHSON_ITERATIONS);
            [self.calculationProgressIndicator setProgress: prog animated:YES];
        });
        float bestGuess = -1.0; // nonsense value is a flag for unused variable;
        float epsilon = NEWTON_RAPHSON_EPSILON;
        float guessedAlt, newGuessedAlt;
        /*
         The Newton-Raphson method uses the derivative at a point to guide the next guess
         to reach the nearest zero point of a function.
         We will estimate the derivative by taking the altitude function at two closely-
         spaced Cd values.
         */
        for (int x = 0; x < NEWTON_RAPHSON_ITERATIONS; x++){
            [self.physicsModel resetFlight];
            guessedAlt = self.physicsModel.fastApogee;
            float altDifference = guessedAlt - actualAlt;
            if (fabsf(altDifference) < (actualAlt * NEWTON_RAPHSON_TOLERANCE)) {     // close enough to say we are done
                bestGuess = [self.physicsModel.rocket cdAtTime:0.0];
                newGuessedAlt = guessedAlt;
            } else {
                // calculate the "derivative"
                float oldCd = tempRocket.cd;
                float newCd = oldCd + epsilon;
                tempRocket.cd = newCd;
                self.physicsModel.rocket = tempRocket;
                [self.physicsModel resetFlight];
                newGuessedAlt = self.physicsModel.fastApogee;
                float slope = (newGuessedAlt - guessedAlt)/epsilon;  // presumably always a negative slope
                
                // walk back along the slope to guess the next value
                newCd = oldCd - altDifference/slope;
                
                // get ready for the next iteration
                tempRocket.cd = newCd;
                self.physicsModel.rocket = tempRocket;
                epsilon /= NEWTON_RAPHSON_EPSILON_SCALING_FACTOR;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.calculationProgressIndicator setProgress: (float)(2.0 + x)/(NEWTON_RAPHSON_ITERATIONS) animated:YES];
                    self.cdLabel.text = [NSString stringWithFormat:@"%1.2f",newCd];
                    self.altitudeLabel.text = [NSString stringWithFormat:@"%1.0f %@", [SLUnitsConvertor displayUnitsOf:newGuessedAlt forKey:ALT_UNIT_KEY], [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY]];
                });
            }
        }
        if (bestGuess < 0){ // we did not short-circuit
            bestGuess = tempRocket.cd;
        }
        // put the new best guess into the display
        dispatch_async(dispatch_get_main_queue(), ^{
            self.cdLabel.text = [NSString stringWithFormat:@"%1.2f",bestGuess];
            self.altitudeLabel.text = [NSString stringWithFormat:@"%1.0f %@", [SLUnitsConvertor displayUnitsOf:newGuessedAlt forKey:ALT_UNIT_KEY], [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY]];
            [self.calculationProgressIndicator setProgress:0.0 animated:YES];
        });
        self.physicsModel.rocket = self.rocket;
    });
}

#pragma mark - UITextFieldDelegate methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    [textField resignFirstResponder];
    [self calculateNewCd:nil];
    return YES;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.splitViewController){
        self.tableView.backgroundColor = [SLCustomUI iPadBackgroundColor];
        return;
    }
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
    [backgroundView setImage:backgroundImage];
    self.tableView.backgroundView = backgroundView;
}


-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:NO animated:animated];
    
    self.cdEstimateField.text = [NSString stringWithFormat:@"%1.2f", self.rocket.cd];
    self.rocketName.text = self.rocket.name;
    self.motorName.text = [self.physicsModel.rocket motorDescription];
    self.motorManufacturerLogo.image = [UIImage imageNamed:self.physicsModel.rocket.motorManufacturer];
    self.cdLabel.text = [NSString stringWithFormat:@"%1.2f", self.rocket.cd];
    self.altUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    self.altitudeLabel.text = [NSString stringWithFormat:@"%1.0f %@", [SLUnitsConvertor displayUnitsOf:self.physicsModel.fastApogee forKey:ALT_UNIT_KEY], [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY]];
    self.cdEstimateField.delegate = self;
    self.actualAltitudeField.delegate = self;
    if (![self.physicsModel.rocket.motors count]) [self.saveButton setEnabled:NO];
    
    //This is my first ever attempt at registering for a notification.  And I'm using a BLOCK!  I must be nuts.
    __weak SLSaveFlightDataTVC *myWeakSelf = self;

    self.iCloudObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil queue:nil usingBlock:^(NSNotification *notification){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *changedKeys = [notification userInfo][NSUbiquitousKeyValueStoreChangedKeysKey];
        for (NSString *key in changedKeys) {
            [defaults setObject:[store objectForKey:key] forKey:key];       // right now this can only be the favorite rockets dictionary
        }
        Rocket *possiblyChangedRocket = [defaults dictionaryForKey:FAVORITE_ROCKETS_KEY][myWeakSelf.rocket.name];
        if (possiblyChangedRocket){
            myWeakSelf.rocket = possiblyChangedRocket;
        }else{ // somebody deleted or renamed the current rocket, so we will put it back in under the current name to avoid confusion
            NSMutableDictionary *rocketFavorites = [[defaults dictionaryForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
            rocketFavorites[myWeakSelf.rocket.name] = myWeakSelf.rocket;
            [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
            [store setDictionary:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
        }
        [defaults synchronize];
        dispatch_async(dispatch_get_main_queue(), ^{
            [myWeakSelf.tableView reloadData];
        });
    }];
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self.iCloudObserver];
    self.iCloudObserver = nil;
    [super viewWillDisappear:animated];
}

-(void)dealloc{
    self.flightData = nil;
    self.rocket = nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return [SLCustomUI headerHeight];
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    NSString *footerText;
    if (section == 0){
        footerText = NSLocalizedString(@"Refining the Cd may take a few sec.", @"Refining the Cd may take a few sec. (header)");
    }else{  // must be last section - there are only two
        footerText = NSLocalizedString(@"New Estimate Results", @"New Estimate Results (header)");
    }
    UILabel *footerLabel = [[UILabel alloc] init];
    [footerLabel setTextColor:[SLCustomUI headerTextColor]];
    [footerLabel setBackgroundColor:self.tableView.backgroundColor];
    [footerLabel setTextAlignment:NSTextAlignmentCenter];
    [footerLabel setText:footerText];
    [footerLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
    
    return footerLabel;
}

#pragma mark - UITextField delegate

- (IBAction)endTextEditing:(UITextField *)sender {
    [sender resignFirstResponder];
}

-(NSString *)description{
    return [NSString stringWithFormat:@"SaveFlightDataTCV for rocket: %@ and motor %@", self.rocket, self.flightData[FLIGHT_MOTOR_LONGNAME_KEY]];
}

@end
