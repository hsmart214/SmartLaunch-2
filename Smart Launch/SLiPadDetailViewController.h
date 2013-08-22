//
//  SLiPadDetailViewController.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 3/9/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

@import UIKit;
#import "SLSimulationDelegate.h"
#import "SLPhysicsModel.h"

@interface SLiPadDetailViewController : UIViewController

@property (nonatomic, weak) id<SLSimulationDelegate> simDelegate;
@property (nonatomic, weak) id<SLSimulationDataSource>simDataSource;
@property (nonatomic, weak) id<SLPhysicsModelDatasource> dataSource;
@property (nonatomic, weak) SLPhysicsModel *model;

-(void)updateDisplay;

@end
