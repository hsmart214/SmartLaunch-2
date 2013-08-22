//
//  SLClusterMotorMemberCell.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

@import UIKit;

@class SLClusterMotorMemberCell;

@protocol SLMotorGroupDelegate <NSObject>

-(void)SLClusterMotorMemberCell:(SLClusterMotorMemberCell *)sender didChangeStartDelay:(float)time;
-(BOOL)allowsSimulationUpdates;

@end

@interface SLClusterMotorMemberCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *delayTextLabel;
@property (weak, nonatomic) IBOutlet UIStepper *delayTimeStepper;
@property (weak, nonatomic) IBOutlet UILabel *motorMountSizeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *manufacturerLogoImageView;
@property (weak, nonatomic) IBOutlet UILabel *motorCountTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *burnTimeTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *burnoutTimeTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorDetailTextLabel;

@property (nonatomic) float oldStartDelayValue;     // used to revert if the sim is not allowing updates

@property (weak, nonatomic) id<SLMotorGroupDelegate>delegate;

@end
