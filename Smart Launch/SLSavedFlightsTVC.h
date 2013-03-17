//
//  SLSavedFlightsTVC.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 1/12/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Rocket.h"
#import "SLSimulationDelegate.h"

@protocol SLSavedFlightsDelegate <NSObject>

@required

-(void)SLSavedFlightsTVC:(id)sender didUpdateSavedFlights:(NSArray *)savedFlights;

@end

@interface SLSavedFlightsTVC : UITableViewController
//model
@property (nonatomic, copy) Rocket* rocket;
@property (nonatomic, weak) id<SLSavedFlightsDelegate> rocketDelegate;
@property (nonatomic, weak) id<SLSimulationDelegate> simDelegate;

@end
