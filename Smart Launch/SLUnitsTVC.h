//
//  SLUnitsTVC.h
//  Smart Launch
//
//  Created by J. Howard Smart on 7/4/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLSimulationDelegate.h"
#import "SLModalPresenterDelegate.h"

@interface SLUnitsTVC : UITableViewController<UIActionSheetDelegate>

@property (nonatomic, weak) id<SLSimulationDelegate> delegate;

+ (void)setStandardDefaults;

@end
