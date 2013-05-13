//
//  SLMotorTableViewController.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLSimulationDelegate.h"

@interface SLMotorTableViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>

@property (copy, nonatomic) NSArray *motors;
@property (copy, nonatomic) NSString *sectionKey;
@property (weak, nonatomic) id<SLSimulationDelegate> delegate;
@property (weak, nonatomic) UIViewController *popBackViewController;

@end
