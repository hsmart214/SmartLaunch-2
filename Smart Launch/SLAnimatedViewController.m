//
//  SLAnimatedViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/25/12.
//  Copyright (c) 2012 J. HOWARD SMART. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SLAnimatedViewController.h"
#import "SLDefinitions.h"       
#import "SLUnitsConvertor.h"
#import "SLAnimatedRocketView.h"

@interface SLAnimatedViewController ()

@property (weak, nonatomic) IBOutlet SLAnimatedRocketView *rocketView;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffVelocityUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *windVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *ffAoALabel;

@end

@implementation SLAnimatedViewController

- (void)drawVectors{
    float wind = [[self.dataSource windVelocity] floatValue];
    float velocity = [[self.dataSource freeFlightVelocity] floatValue];
    float launchAngle = [[self.dataSource launchAngle] floatValue];
    [self.rocketView tiltRocketToAngle:-launchAngle];
    [self.rocketView UpdateVectorsWithRocketVelocity:velocity andWindVelocity:wind];
}

- (void)updateDisplay{
    self.windVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    NSNumber *velocity = [SLUnitsConvertor displayUnitsOf:[self.dataSource windVelocity] forKey:VELOCITY_UNIT_KEY];
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", [velocity floatValue]];
    
    self.ffVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    velocity = [SLUnitsConvertor displayUnitsOf:[self.dataSource freeFlightVelocity] forKey:VELOCITY_UNIT_KEY];
    self.ffVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", [velocity floatValue]];
    
    NSNumber *aoa = [self.dataSource freeFlightAoA];
    self.ffAoALabel.text = [NSString stringWithFormat:@"%1.1f", [aoa floatValue] * DEGREES_PER_RADIAN];
    [self drawVectors];
}

- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setRocketView:nil];
    [self setWindVelocityUnitsLabel:nil];
    [self setFfVelocityUnitsLabel:nil];
    [self setWindVelocityLabel:nil];
    [self setFfVelocityLabel:nil];
    [self setFfAoALabel:nil];
    [self setRocketView:nil];
    [super viewDidUnload];
}
@end
