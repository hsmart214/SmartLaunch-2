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
@property (weak, nonatomic) IBOutlet UISlider *windVelocitySlider;

@end

@implementation SLAnimatedViewController

- (IBAction)windVelocityChanged:(UISlider *)sender {
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%2.1f", sender.value];
    [self drawVectors];
}

- (void)drawVectors{
    float wind = self.windVelocitySlider.value;
    float velocity = [[self.dataSource freeFlightVelocity] floatValue];
    float launchAngle = [[self.dataSource launchAngle] floatValue];
    enum LaunchDirection dir = [self.dataSource launchGuideDirection];
    if (dir == CrossWind) launchAngle = 0.0;           // crosswind the AoA is the same as upright
    
    [self.rocketView tiltRocketToAngle:launchAngle];   // in the model the launch angle is always positive
    
    if (dir == IntoWind) wind = -wind;                 // this is how we display the opposite wind direction
    
    [self.rocketView UpdateVectorsWithRocketVelocity:velocity andWindVelocity:wind];
}

- (void)updateDisplay{
    
    self.ffVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    NSNumber *velocity = [SLUnitsConvertor displayUnitsOf:[self.dataSource freeFlightVelocity] forKey:VELOCITY_UNIT_KEY];
    self.ffVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", [velocity floatValue]];
    
    NSNumber *aoa = [self.dataSource freeFlightAoA];
    self.ffAoALabel.text = [NSString stringWithFormat:@"%1.1f", [aoa floatValue] * DEGREES_PER_RADIAN];
    [self drawVectors];
}

- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:NO animated:animated];
    self.windVelocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    NSNumber *velocity = [SLUnitsConvertor displayUnitsOf:[self.dataSource windVelocity] forKey:VELOCITY_UNIT_KEY];
    self.windVelocityLabel.text = [NSString stringWithFormat:@"%1.1f", [velocity floatValue]];
    self.windVelocitySlider.value = [velocity floatValue];
    [self updateDisplay];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    NSString *backgroundFileName = [[NSBundle mainBundle] pathForResource: BACKGROUND_IMAGE_FILENAME ofType:@"png"];
    UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:backgroundFileName];
    [backgroundView setImage:backgroundImage];
    [self.view insertSubview:backgroundView atIndex:0];
    [self.rocketView startFresh];
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
    [self setWindVelocitySlider:nil];
    [super viewDidUnload];
}
@end
