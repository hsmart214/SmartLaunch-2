//
//  SLCustomUI.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 3/28/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLCustomUI.h"

@implementation SLCustomUI

+(UIColor *)iPadBackgroundColor{
    return [UIColor colorWithRed:13.0/256 green:30.0/256 blue:84.0/256 alpha:1.0];
}

#pragma mark - UITableViewDelegate interface

+(CGFloat)headerHeight{
    return 30.0;
}
+(CGFloat)footerHeight{
    return [SLCustomUI headerHeight];
}
+(UIColor *)headerTextColor{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return [UIColor whiteColor];
    }else{
        return [UIColor darkTextColor];
    }
}
+(UIColor *)footerTextColor{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return [UIColor whiteColor];
    }else{
        return [UIColor darkTextColor];
    }
}

#pragma mark - Angle Vector Colors

+(UIColor *)windVectorColor{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return [UIColor colorWithRed:204.0/256 green:235.0/256 blue:1.0 alpha:1.0];
    }else{
        return [UIColor purpleColor];
    }}
+(UIColor *)thrustVectorColor{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return [UIColor colorWithRed:149.0/256 green:188.0/256 blue:1.0 alpha:1.0];
    }else{
        return [UIColor blueColor];
    }
}
+(UIColor *)AoAVectorColor{
    return [UIColor redColor];
}

#pragma mark - SLGraphView interface colors

+(UIColor *)graphTextColor{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return [UIColor whiteColor];
    }else{
        return [UIColor darkTextColor];
    }
}
+(UIColor *)curveGraphCurveColor{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return [UIColor cyanColor];
    }else{
        return [UIColor redColor];
    }
}

+(UIColor *)machLineColor{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return [UIColor redColor];
    }else{
        return [UIColor blueColor];
    }
}


@end
