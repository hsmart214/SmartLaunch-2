//
//  SLCustomUI.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 3/28/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

@import UIKit;
@import Foundation;

@interface SLCustomUI : NSObject

+(UIColor *)iPadBackgroundColor;
+(CGFloat)headerHeight;
+(CGFloat)footerHeight;
+(UIColor *)headerTextColor;
+(UIColor *)headerBackgroundColor;
+(UIColor *)footerTextColor;

+(UIColor *)windVectorColor;
+(UIColor *)thrustVectorColor;
+(UIColor *)AoAVectorColor;

+(UIColor *)axisColor;
+(UIColor *)graphTextColor;
+(UIColor *)graphHashColor;
+(UIColor *)curveGraphCurveColor;
+(UIColor *)curveGraphBackgroundColor;
+(UIColor *)machLineColor;
+(UIColor *)angleNeedleColor;

@end
