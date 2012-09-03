//
//  SLPhotoAngleFinderDelegate.h
//  Snoopy
//
//  Created by J. HOWARD SMART on 7/30/12.
//
//

#import <Foundation/Foundation.h>

@protocol SLPhotoAngleFinderDelegate <NSObject>
@required
- (void)didAcceptPhotoLaunchAngle:(NSNumber *)angle;
- (void)didCancelPhotoLaunchAngle;

@end
