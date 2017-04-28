//
//  UIViewController+ContentViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/27/17.
//  Copyright © 2017 J. HOWARD SMART. All rights reserved.
//

#import "UIViewController+ContentViewController.h"

@implementation UIViewController (ContentViewController)

-(UIViewController *)contentViewController{
    if ([self class] == [UINavigationController class]){
        return ((UINavigationController *)self).visibleViewController;
    }else{
        return self;
    }
}

@end
