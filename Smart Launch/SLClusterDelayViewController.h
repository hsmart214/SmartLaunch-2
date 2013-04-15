//
//  SLClusterDelayViewController.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLClusterMotorBuildViewController.h"

@interface SLClusterDelayViewController : UIViewController

@property (nonatomic, weak) id<SLClusterBuildDelegate> delegate;
@property (nonatomic, weak) id<SLClusterBuildDatasource> datasource;

@end
