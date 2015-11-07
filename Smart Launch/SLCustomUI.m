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
    return [UIColor whiteColor];
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
//        return [UIColor whiteColor];
//    }else{
//        return [UIColor darkTextColor];
//    }
}

+(UIColor *)headerBackgroundColor{
    return [UIColor colorWithRed:5.0/256 green:65.0/256 blue:49.0/256 alpha:1.0];
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

+(UIColor *)angleNeedleColor{
    return [UIColor colorWithRed:0.0 green:0.78 blue:.072 alpha:1.0];
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

+(UIColor *)curveGraphBackgroundColor{
    return [UIColor colorWithRed:1.0/256.0 green:156.0/256.0 blue:170.0/256.0 alpha:0.1];
}

+(UIColor *)machLineColor{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return [UIColor redColor];
    }else{
        return [UIColor blueColor];
    }
}


@end
