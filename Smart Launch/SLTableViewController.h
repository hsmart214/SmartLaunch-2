//
//  SLTableViewController.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/26/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLSimulationDelegate.h"
#import "SLDefinitions.h"
#import "SLUnitsConvertor.h"

@interface SLTableViewController : UITableViewController <SLSimulationDelegate, SLSimulationDataSource>

@end
