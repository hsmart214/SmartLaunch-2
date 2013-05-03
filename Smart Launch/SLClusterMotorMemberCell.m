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
    if ([self.delegate allowsSimulationUpdates]){
        self.delayTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Delay %1.1f sec", @"Delay %1.1f sec"), [sender value]];
        self.oldStartDelayValue = sender.value;
        [self.delegate SLClusterMotorMemberCell:self didChangeStartDelay:[self.delayTimeStepper value]];
        [self updateStartDelay];
    }else{
        [sender setValue: self.oldStartDelayValue];
    }
}


-(void)updateStartDelay{
    float time = [self.delayTimeStepper value];
    [self.delegate SLClusterMotorMemberCell:self didChangeStartDelay:time];
}

@end
