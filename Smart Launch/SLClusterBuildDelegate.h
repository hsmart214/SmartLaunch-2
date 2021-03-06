//
//  SLClusterBuildDelegate.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/25/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

@import Foundation;

@protocol SLClusterBuildDelegate <NSObject>

-(void)changeDelayTimeTo:(float)delay forGroupAtIndex:(NSUInteger)index;
-(void)replaceMotorLoadoutPlist:(NSArray *)motorLoadoutPlist;
-(void)deleteSavedMotorLoadoutAtIndex:(NSUInteger)index;

@end

@protocol SLClusterBuildDatasource <NSObject>

@property (nonatomic, readonly) NSUInteger selectedGroupIndex;
@property (nonatomic, strong) NSArray *motorConfiguration;      // array of NSDictionary * {count, diam}
@property (nonatomic, strong) NSArray *savedMotorLoadoutPlists;

@end

