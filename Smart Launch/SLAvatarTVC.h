//
//  SLAvatarTVC.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/7/15.
//  Copyright © 2015 J. HOWARD SMART. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SLAvatarTVC;
@protocol SLAvatarDelegate <NSObject>

@optional

-(void)avatarTVC:(SLAvatarTVC *)sender didPickAvatarNamed:(NSString *)avatarName;

@end

@interface SLAvatarTVC : UITableViewController

@property (nonatomic, weak) id<SLAvatarDelegate> delegate;
@property (nonatomic, copy) NSString *avatar;

@end
