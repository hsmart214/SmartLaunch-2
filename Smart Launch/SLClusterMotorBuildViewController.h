//
//  SLClusterMotorBuildViewController.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLClusterTableViewController.h"
#import "SLClusterMotor.h"
#import "SLSimulationDelegate.h"

@protocol SLClusterBuildDelegate <NSObject>

-(void)changeDelayTimeTo:(NSNumber *)delay sender:(id)sender;

@end

@protocol SLClusterBuildDatasource <NSObject>

-(SLClusterMotor *)clusterSoFar;

@end

@interface SLClusterMotorBuildViewController : UITableViewController<SLSimulationDelegate>

@property (nonatomic, weak) id<SLClusterListDelegate> delegate;
@property (nonatomic, strong) SLClusterMotor *clusterMotor;

@end
