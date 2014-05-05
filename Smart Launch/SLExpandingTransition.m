//
//  SLExpandingTransition.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 3/1/14.
//  Copyright (c) 2014 J. HOWARD SMART. All rights reserved.
//

#import "SLExpandingTransition.h"

@implementation SLExpandingTransition

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 1.0;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // get the destination view controller
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    // get a snapshot of the destination view and make it the same size as the sender view
    UIView *toViewSnapshot = [toVC.view snapshotViewAfterScreenUpdates:YES];
    toViewSnapshot.alpha = 0.0;
    // put the view in the container of the animation
    UIView *container = [transitionContext containerView];
    [container addSubview:toViewSnapshot];
    
    //animate from the existing view to the snapshot view of the new one
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                         toViewSnapshot.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                         [toViewSnapshot removeFromSuperview];
                         [container addSubview:toVC.view];
                         
                         [transitionContext completeTransition:YES];
                     }];
    
}

@end
