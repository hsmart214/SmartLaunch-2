//
//  SLMotorConfigurationTVC.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/23/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

@import UIKit;

@class SLMotorConfigurationTVC;

@protocol SLMotorConfigurationDataSource <NSObject>

-(NSArray *)currentMotorConfiguration;

@end

@protocol SLMotorConfigurationDelegate <NSObject>

-(void)SLMotorConfigurationTVC:(SLMotorConfigurationTVC *)sender didChangeMotorConfiguration:(NSArray *)configuration;
-(void)dismissModalVC;

@end

@interface SLMotorConfigurationTVC : UITableViewController

@property (nonatomic, weak) id<SLMotorConfigurationDelegate> configDelegate;
@property (nonatomic, weak) id<SLMotorConfigurationDataSource> configDatasource;

@end
