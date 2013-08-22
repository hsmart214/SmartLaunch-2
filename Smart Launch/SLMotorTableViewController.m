//
//  SLMotorTableViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) All rights reserved.
//

#import "SLMotorTableViewController.h"
#import "SLMotorSearchViewController.h"
#import "SLMotorViewController.h"
#import "SLClusterMotor.h"

@interface SLMotorTableViewController ()
@property (nonatomic, strong) NSDictionary *selectedMotorDict;
@property (nonatomic, strong) RocketMotor *selectedMotor;
@end

@implementation SLMotorTableViewController 

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{    
    return [self.motors count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [(self.motors)[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MotorCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSDictionary *motorDict = (self.motors)[indexPath.section][indexPath.row];
    
    cell.textLabel.text = motorDict[NAME_KEY];
    cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Propellant %5.0f g", @"Propellant %5.0f g") ,[motorDict[PROP_MASS_KEY] floatValue] * 1000];
//    NSString *path = [[NSBundle mainBundle] pathForResource:[motorDict objectForKey:MAN_KEY] ofType:@"png"];
//    UIImage *theImage = [UIImage imageWithContentsOfFile:path];
    //this way the image is cached automatically.  Should make scrolling faster.
    cell.imageView.image = [UIImage imageNamed:motorDict[MAN_KEY]];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    // use the first object in the section to tell us what the header name should be
    if ([(self.motors)[section] count]!=0) {
        return (self.motors)[section][0][self.sectionKey];
    } else {
        return nil;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedMotorDict = (self.motors)[indexPath.section][indexPath.row];
    self.selectedMotor = [RocketMotor motorWithMotorDict:self.selectedMotorDict];
    [self.delegate sender:self didChangeRocketMotor:@[@{MOTOR_COUNT_KEY: @1,
          MOTOR_PLIST_KEY: [self.selectedMotor motorDict]}]];
    [self.navigationController popToViewController:self.popBackViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    self.selectedMotorDict = (self.motors)[indexPath.section][indexPath.row];
    self.selectedMotor = [RocketMotor motorWithMotorDict:self.selectedMotorDict];
    [self.delegate sender:self didChangeRocketMotor:@[@{MOTOR_COUNT_KEY: @1,
          MOTOR_PLIST_KEY: [self.selectedMotor motorDict]}]];
    [self performSegueWithIdentifier:@"motorDetailSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell *)sender{
    if ([segue.identifier isEqualToString:@"motorDetailSegue"]){
        [(SLMotorViewController *)segue.destinationViewController setMotor:self.selectedMotor];
        [(SLMotorViewController *)segue.destinationViewController setDelegate:self.delegate];
        [(SLMotorViewController *)segue.destinationViewController setPopBackViewController:self.popBackViewController];
        [segue.destinationViewController setTitle:self.selectedMotor.name];
    }
}

#pragma mark - View life cycle

-(void)viewDidLoad{
    [super viewDidLoad];
    if (self.splitViewController){
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_FOR_IPAD_MASTER_VC];
        [backgroundView setImage:backgroundImage];
        [self.tableView setBackgroundView:backgroundView];
    }
}

-(void)dealloc{
    self.selectedMotor = nil;
    self.selectedMotorDict = nil;
    self.sectionKey = nil;
    self.motors = nil;
}

-(NSString *)description{
    return @"MotorTVC";
}

@end
