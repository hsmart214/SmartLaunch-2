//
//  SLCustomUI.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 3/28/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SLCustomUI : NSObject

+(UIColor *)iPadBackgroundColor;
+(CGFloat)headerHeight;
+(CGFloat)footerHeight;
+(UIColor *)headerTextColor;
+(UIColor *)footerTextColor;

+(UIColor *)windVectorColor;
+(UIColor *)thrustVectorColor;
+(UIColor *)AoAVectorColor;

+(UIColor *)graphTextColor;
+(UIColor *)curveGraphCurveColor;
+(UIColor *)machLineColor;

@end
