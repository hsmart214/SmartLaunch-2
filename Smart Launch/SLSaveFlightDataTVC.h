//
//  SLSaveFlightDataTVC.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 1/13/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

@import UIKit;
#import "Rocket.h"
#import "SLPhysicsModel.h"
#import "SLRocketPropertiesTVC.h"

@interface SLSaveFlightDataTVC : UITableViewController
//model
@property (nonatomic, strong) NSDictionary *flightData;
@property (nonatomic, copy) Rocket *rocket;
@property (nonatomic, weak) SLPhysicsModel *physicsModel;
@property (nonatomic, weak) id<SLSimulationDelegate> delegate;

@end
