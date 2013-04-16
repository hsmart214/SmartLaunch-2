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

-(void)changeDelayTimeTo:(float)delay sender:(id)sender;

@end

@protocol SLClusterBuildDatasource <NSObject>

@property (nonatomic, readonly) NSUInteger selectedMotorIndex;

-(SLClusterMotor *)clusterSoFar;
-(float)timeToFirstBurnout;

@end

@interface SLClusterMotorBuildViewController : UITableViewController<SLSimulationDelegate, SLClusterBuildDelegate, SLClusterBuildDatasource>

@property (nonatomic, weak) id<SLClusterListDelegate> delegate;
@property (nonatomic, strong) SLClusterMotor *clusterMotor;

@end
