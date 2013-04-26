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

@protocol  SLClusterBuildDelegate <NSObject>

-(void)changeDelayTimeTo:(float)delay forGroupAtIndex:(NSUInteger)index;

@end

@protocol SLClusterBuildDatasource <NSObject>

@property (nonatomic, readonly) NSUInteger selectedGroupIndex;
@property (nonatomic, strong) NSArray *motorConfiguration;      // array of NSDictionary * {count, diam}

-(NSArray *)burnoutTimes;

@end

@interface SLClusterMotorBuildViewController : UITableViewController<SLSimulationDelegate>

@property (nonatomic, weak) id<SLClusterListDelegate> delegate;
@property (nonatomic, strong) NSArray *motorLoadoutPlist;           // array of NSDictionary * {count, motorDict}

@end
