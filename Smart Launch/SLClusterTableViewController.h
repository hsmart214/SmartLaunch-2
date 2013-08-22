//
//  SLClusterTableViewController.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

@import UIKit;
#import "SLSimulationDelegate.h"
#import "SLClusterBuildDelegate.h"

@interface SLClusterTableViewController : UITableViewController

@property (nonatomic, weak) id<SLClusterBuildDelegate, SLSimulationDelegate> clusterDelegate;
@property (nonatomic, weak) id<SLClusterBuildDatasource> clusterDatasource;
@property (nonatomic, weak) NSArray *motorLoadouts;

@end
