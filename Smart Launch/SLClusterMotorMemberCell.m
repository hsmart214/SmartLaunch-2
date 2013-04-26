//
//  SLClusterMotorMemberCell.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterMotorMemberCell.h"

@implementation SLClusterMotorMemberCell

- (IBAction)delayTimeChanged:(UIStepper *)sender {
    self.delayTextLabel.text = [NSString stringWithFormat:@"Ignition Delay %1.1f sec", [sender value]];
    [self updateStartDelay];
}

- (IBAction)delayBasisChanged:(UISegmentedControl *)sender {
    [self updateStartDelay];
}

-(void)updateStartDelay{
    float time = [self.delayTimeStepper value];
    [self.delegate SLClusterMotorMemberCell:self didChangeStartDelay:time fromBurnout:(BOOL)self.delayBasisSelector.selectedSegmentIndex];
}

@end
