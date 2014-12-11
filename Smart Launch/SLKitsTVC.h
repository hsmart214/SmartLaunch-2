//
//  SLKitsTVC.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 9/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SLKitsTVC;
@protocol SLKitTVCDelegate <NSObject>
@optional
- (void)SLKitTVC:(id)sender didChooseCommercialKit:(NSDictionary *)kitDict;

@end

@interface SLKitsTVC : UITableViewController

@property (nonatomic, weak) id<SLKitTVCDelegate> delegate;
@property (nonatomic, strong) NSArray *kits;

@end
