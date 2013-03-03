//
//  SLFlightProfileViewController.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 2/3/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLPhysicsModel.h"
#import "SLCurveGraphView.h"

@interface SLFlightProfileViewController : UIViewController<SLCurveGraphViewDataSource, SLCurveGraphViewDelegate>

@property (nonatomic, weak) id<SLPhysicsModelDatasource> dataSource;
@property (nonatomic, weak) id delegate;    // This dummy is unused - only to avoid awkward recoding of the prepare method

@end
