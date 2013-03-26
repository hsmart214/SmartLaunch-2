//
//  SLRocketsTableViewController.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Rocket.h"
#import "SLRocketPropertiesTVC.h"
#import "SLSimulationDelegate.h"

@interface SLRocketsTableViewController : UITableViewController <SLRocketPropertiesTVCDelegate>

@property (weak, nonatomic) id<SLSimulationDelegate> delegate;

@end
