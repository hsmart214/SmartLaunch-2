//
//  SLAnimatedViewController.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/25/12.
//  Copyright (c) 2012 All rights reserved.
//

@import UIKit;
#import "SLSimulationDelegate.h"


@interface SLAnimatedViewController : UIViewController

@property (nonatomic, weak) id<SLSimulationDelegate> delegate;
@property (nonatomic, weak) id<SLSimulationDataSource> dataSource;
@property (nonatomic, getter= isInRSOMode) BOOL inRSOMode;

@end
