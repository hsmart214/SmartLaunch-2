//
//  SLSimSettingsViewController.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/26/12.
//  Copyright (c) 2012 All rights reserved.
//

@import UIKit;
@import CoreLocation;
#import "SLSimulationDelegate.h"
#import "SLUnitsConvertor.h"


@interface SLSimSettingsViewController : UITableViewController <SLSimulationDelegate>

@property (nonatomic, weak) id <SLSimulationDelegate> delegate;

@end
