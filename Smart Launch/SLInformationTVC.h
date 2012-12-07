//
//  SLInformationTVC.h
//  Snoopy
//
//  Created by J. Howard Smart on 7/3/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLSimulationDelegate.h"
#import "SLModalPresenterDelegate.h"
#import "SLUnitsTVC.h"
#import "SLDefinitions.h"

@interface SLInformationTVC : UITableViewController<SLModalPresenterDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) id<SLSimulationDelegate> delegate;

@end
