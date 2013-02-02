//
//  SLSaveFlightDataTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 1/13/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

/* I think this controller needs to respond to iCloud updates because it holds a strong Rocket*
 which may change externally */

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
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refineCdButton;
@property (weak, nonatomic) IBOutlet UIProgressView *calculationProgressIndicator;
@property (weak, nonatomic) IBOutlet UILabel *cdLabel;
@property (weak, nonatomic) IBOutlet UILabel *windDirectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *altitudeLabel;
@property (strong, nonatomic) id iCloudObserver;

@end

@implementation SLSaveFlightDataTVC

- (IBAction)cancelFlightSaving:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveFlightData:(UIBarButtonItem *)sender {
    float cd = [self.cdLabel.text floatValue];
    float alt = [self.actualAltitudeField.text floatValue];
    self.rocket.cd = @(cd);
    NSMutableDictionary *newFlightData = [self.flightData mutableCopy];
    newFlightData[FLIGHT_BEST_CD] = @(cd);
    newFlightData[FLIGHT_ALTITUDE_KEY] = [SLUnitsConvertor metricStandardOf:@(alt) forKey:ALT_UNIT_KEY];
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
    [store setObject:rocketPlists forKey:FAVORITE_ROCKETS_KEY];
    [defaults synchronize];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)calculateNewCd:(UIBarButtonItem *)sender {
    if ([self.actualAltitudeField.text floatValue] == 0.0) return;
    float initialGuess = [self.cdEstimateField.text floatValue];
    __block Rocket *tempRocket = [self.rocket copyWithZone:nil];
    tempRocket.cd = @(initialGuess);
    self.physicsModel.rocket = tempRocket;
    
    //need to do this in a separate thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            float prog = 1.0/(NEWTON_RAPHSON_ITERATIONS);
            [self.calculationProgressIndicator setProgress: prog animated:YES];
        });
        float bestGuess = -1.0; // nonsense value is a flag for unused variable;
        float actualAlt = [self.actualAltitudeField.text floatValue];
        actualAlt = [[SLUnitsConvertor metricStandardOf:@(actualAlt) forKey:ALT_UNIT_KEY] floatValue];
        float epsilon = NEWTON_RAPHSON_EPSILON;
        float guessedAlt, newGuessedAlt;
        /*
         The Newton-Raphson method uses the derivative at a point to guide the next guess
         to reach the nearest zero point of a function.
         We will estimate the derivative by taking the altitude function at two closely-
         spaced Cd values.
         */
        for (int x = 0; x < NEWTON_RAPHSON_ITERATIONS; x++){
            guessedAlt = self.physicsModel.fastApogee;
            float altDifference = guessedAlt - actualAlt;
            if (fabsf(altDifference) < (actualAlt * NEWTON_RAPHSON_TOLERANCE)) {     // close enough to say we are done
                bestGuess = [self.physicsModel.rocket.cd floatValue];
                newGuessedAlt = guessedAlt;
            } else {
                // calculate the "derivative"
                float oldCd = [tempRocket.cd floatValue];
                float newCd = oldCd + epsilon;
                tempRocket.cd = @(newCd);
                self.physicsModel.rocket = tempRocket;
                newGuessedAlt = self.physicsModel.fastApogee;
                float slope = (newGuessedAlt - guessedAlt)/epsilon;  // presumably always a negative slope
                
                // walk back along the slope to guess the next value
                newCd = oldCd - altDifference/slope;
                
                // get ready for the next iteration
                tempRocket.cd = @(newCd);
                self.physicsModel.rocket = tempRocket;
                epsilon /= NEWTON_RAPHSON_EPSILON_SCALING_FACTOR;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.calculationProgressIndicator setProgress: (float)(2.0 + x)/(NEWTON_RAPHSON_ITERATIONS) animated:YES];
                    self.cdLabel.text = [NSString stringWithFormat:@"%1.2f",newCd];
                    self.altitudeLabel.text = [NSString stringWithFormat:@"%1.0f %@", [[SLUnitsConvertor displayUnitsOf:@(newGuessedAlt) forKey:LENGTH_UNIT_KEY] floatValue], [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY]];
                });
            }
        }
        if (bestGuess < 0){ // we did not short-circuit
            bestGuess = [tempRocket.cd floatValue];
        }
        // put the new best guess into the display
        dispatch_async(dispatch_get_main_queue(), ^{
            self.cdLabel.text = [NSString stringWithFormat:@"%1.2f",bestGuess];
            self.altitudeLabel.text = [NSString stringWithFormat:@"%1.0f %@", [[SLUnitsConvertor displayUnitsOf:@(newGuessedAlt) forKey:ALT_UNIT_KEY] floatValue], [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY]];
            [self.calculationProgressIndicator setProgress:0.0 animated:YES];
        });
        self.physicsModel.rocket = self.rocket;
    });
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
    [backgroundView setImage:backgroundImage];
    self.tableView.backgroundView = backgroundView;
}


-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:NO animated:animated];
    
    self.cdEstimateField.text = [NSString stringWithFormat:@"%1.2f",[self.rocket.cd floatValue]];
    self.rocketName.text = self.rocket.name;
    self.motorName.text = self.physicsModel.motor.name;
    self.motorManufacturerLogo.image = [UIImage imageNamed:self.physicsModel.motor.manufacturer];
    self.cdLabel.text = [NSString stringWithFormat:@"%1.2f",[self.rocket.cd floatValue]];
    self.altUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    self.altitudeLabel.text = [NSString stringWithFormat:@"%1.0f %@", [[SLUnitsConvertor displayUnitsOf:@(self.physicsModel.fastApogee) forKey:ALT_UNIT_KEY] floatValue], [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY]];
    
    //This is my first ever attempt at registering for a notification.  And I'm using a BLOCK!  I must be nuts.
    self.iCloudObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil queue:nil usingBlock:^(NSNotification *notification){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *changedKeys = [[notification userInfo] objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        for (NSString *key in changedKeys) {
            [defaults setObject:[store objectForKey:key] forKey:key];       // right now this can only be the favorite rockets dictionary
        }
        Rocket *possiblyChangedRocket = [defaults dictionaryForKey:FAVORITE_ROCKETS_KEY][self.rocket.name];
        if (possiblyChangedRocket){
            self.rocket = possiblyChangedRocket;
        }else{ // somebody deleted or renamed the current rocket, so we will put it back in under the current name to avoid confusion
            NSMutableDictionary *rocketFavorites = [[defaults dictionaryForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
            rocketFavorites[self.rocket.name] = self.rocket;
            [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
            [store setDictionary:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
        }
        [defaults synchronize];
    }];
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self.iCloudObserver];
    self.iCloudObserver = nil;
    [super viewWillDisappear:animated];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextField delegate

- (IBAction)endTextEditing:(UITextField *)sender {
    [sender resignFirstResponder];
}

@end
