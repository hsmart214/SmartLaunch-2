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

@interface SLClusterMotorBuildViewController : UITableViewController<SLSimulationDelegate, SLClusterBuildDelegate, SLClusterBuildDatasource>

@property (nonatomic, weak) id delegate;
@property (nonatomic, weak) id<SLSimulationDelegate> simDelegate;
@property (nonatomic, weak) id<SLSimulationDataSource>simDatasource;
@property (nonatomic, strong) NSArray *motorLoadoutPlist;           // array of NSDictionary * {count, motorDict}
@property (nonatomic, strong) NSArray *motorConfiguration;          // array of NSDictionary * {count, motor diameter}
@property (nonatomic, strong) NSArray *savedMotorLoadoutPlists;

@property (nonatomic) NSUInteger selectedGroupIndex;

@end
