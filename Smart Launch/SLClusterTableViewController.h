//
//  SLClusterTableViewController.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLClusterMotor.h"

@protocol SLClusterListDelegate <NSObject>

-(void)changedClusterMotor:(SLClusterMotor *)clusterMotor sender:(id)sender;

@end

@interface SLClusterTableViewController : UITableViewController<SLClusterListDelegate>

@end
