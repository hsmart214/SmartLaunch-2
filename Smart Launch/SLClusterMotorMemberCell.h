//
//  SLClusterMotorMemberCell.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLClusterMotorFirstGroupCell.h"

@class SLClusterMotorMemberCell;

@protocol SLMotorGroupDelegate <NSObject>

-(void)SLClusterMotorMemberCell:(SLClusterMotorMemberCell *)sender didChangeStartDelay:(float)time fromBurnout:(BOOL)fromBurnout;

@end

@interface SLClusterMotorMemberCell : SLClusterMotorFirstGroupCell

@property (weak, nonatomic) IBOutlet UILabel *delayTextLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *delayBasisSelector;
@property (weak, nonatomic) IBOutlet UIStepper *delayTimeStepper;
@property (weak, nonatomic) id<SLMotorGroupDelegate>delegate;

@end
