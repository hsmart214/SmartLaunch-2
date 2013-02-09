//
//  SLModalPresenterDelegate.h
//  Smart Launch
//
//  Created by J. Howard Smart on 7/4/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SLModalPresenterDelegate <NSObject>

@required
- (void)dismissModalVC:(id)sender;

@end
