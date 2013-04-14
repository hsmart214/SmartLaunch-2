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
#import "RocketMotor.h"

//#define CELL_VIEW_HEIGHT 86
//#define CELL_VIEW_WIDTH 140

@interface SLMotorTableViewController ()
@property (nonatomic, strong) NSDictionary *selectedMotorDict;
@property (nonatomic, strong) RocketMotor *selectedMotor;
@end

@implementation SLMotorTableViewController 

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
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
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Propellant %5.0f g",[motorDict[PROP_MASS_KEY] floatValue] * 1000];
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
    [self.delegate sender:self didChangeRocketMotor:self.selectedMotor];
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    self.selectedMotorDict = (self.motors)[indexPath.section][indexPath.row];
    self.selectedMotor = [RocketMotor motorWithMotorDict:self.selectedMotorDict];
    [self.delegate sender:self didChangeRocketMotor:self.selectedMotor];
    [self performSegueWithIdentifier:@"motorDetailSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell *)sender{
    if ([segue.identifier isEqualToString:@"motorDetailSegue"]){
        [(SLMotorViewController *)segue.destinationViewController setMotor:self.selectedMotor];
        [(SLMotorViewController *)segue.destinationViewController setDelegate:self.delegate];
        [segue.destinationViewController setTitle:self.selectedMotor.name];
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
