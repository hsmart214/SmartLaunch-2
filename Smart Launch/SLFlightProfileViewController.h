//
//  SLFlightProfileViewController.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 2/3/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLPhysicsModel.h"
#import "SLMotorThrustCurveView.h"

@interface SLFlightProfileViewController : UIViewController<SLMotorThrustCurveViewDataSource>

@property (nonatomic, weak) id<SLPhysicsModelDatasource> dataSource;

@end
