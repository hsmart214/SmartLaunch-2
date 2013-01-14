//
//  SLFlightDataCell.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 1/12/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SLFlightDataCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *motorName;
@property (weak, nonatomic) IBOutlet UILabel *cd;
@property (weak, nonatomic) IBOutlet UILabel *altitude;
@property (weak, nonatomic) IBOutlet UILabel *altitudeUnitsLabel;

@end
