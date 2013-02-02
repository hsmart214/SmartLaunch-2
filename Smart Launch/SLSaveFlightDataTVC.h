//
//  SLSaveFlightDataTVC.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 1/13/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Rocket.h"
#import "SLPhysicsModel.h"

@interface SLSaveFlightDataTVC : UITableViewController
//model
@property (nonatomic, strong) NSDictionary *flightData;
@property (nonatomic, strong) Rocket *rocket;
@property (nonatomic, weak) SLPhysicsModel *physicsModel;
@property (nonatomic, weak) id delegate;            // this dummy delegate only exists to make the prepareForSegue code easier

@end
