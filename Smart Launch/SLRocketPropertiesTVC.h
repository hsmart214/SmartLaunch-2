//
//  SLRocketPropertiesTVC.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Rocket.h"
#import "SLUnitsConvertor.h"

@class SLRocketPropertiesTVC;

@protocol SLRocketsTVCDelegate
@optional
- (void)SLRocketPropertiesTVC:(SLRocketPropertiesTVC *)sender 
                savedRocket:(Rocket *)rocket;
- (void)SLRocketPropertiesTVC:(SLRocketPropertiesTVC *)sender
              deletedRocket:(Rocket *)rocket;

@end


@interface SLRocketPropertiesTVC : UITableViewController<UITextFieldDelegate>

#pragma mark Model
@property (nonatomic, strong) Rocket *rocket;

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *kitNameField;
@property (weak, nonatomic) IBOutlet UITextField *manField;
@property (weak, nonatomic) IBOutlet UITextField *massField;
@property (weak, nonatomic) IBOutlet UITextField *diamField;
@property (weak, nonatomic) IBOutlet UITextField *lenField;
@property (weak, nonatomic) IBOutlet UITextField *cdField;
@property (weak, nonatomic) IBOutlet UILabel *motorDiamLabel;
// These labels set according to the units prefs
@property (weak, nonatomic) IBOutlet UILabel *massUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *diamUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *lenUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorDiamUnitsLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@property (nonatomic, weak) id <SLRocketsTVCDelegate> delegate;
@end
