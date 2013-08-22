//
//  SLPhotoAngleFinderDelegate.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 7/30/12.
//  Copyright (c) 2012 All rights reserved.
//

@import Foundation;

@protocol SLPhotoAngleFinderDelegate <NSObject>
@required
- (void)didAcceptPhotoLaunchAngle:(NSNumber *)angle;
- (void)didCancelPhotoLaunchAngle;

@end
