//
//  SLRocketPropertiesTVC.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

@import UIKit;
#import "Rocket.h"
#import "SLUnitsConvertor.h"
#import "SLSavedFlightsTVC.h"
#import "SLKitsTVC.h"
#import "SLKitManufacturerTVC.h"


@class SLRocketPropertiesTVC;

@protocol SLRocketPropertiesTVCDelegate
@optional
- (void)SLRocketPropertiesTVC:(SLRocketPropertiesTVC *)sender 
                savedRocket:(Rocket *)rocket;
- (void)SLRocketPropertiesTVC:(SLRocketPropertiesTVC *)sender
              deletedRocket:(Rocket *)rocket;

@end


@interface SLRocketPropertiesTVC : UITableViewController<UITextFieldDelegate, SLSavedFlightsDelegate>

#pragma mark Model
@property (nonatomic, copy) Rocket *rocket;

@property (nonatomic, weak) id <SLRocketPropertiesTVCDelegate> delegate;

-(IBAction)choseRocketKit:(UIStoryboardSegue *)sender;


@end
