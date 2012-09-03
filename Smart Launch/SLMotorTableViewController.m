//
//  SLMotorTableViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import "SLMotorTableViewController.h"
#import "SLMotorSearchViewController.h"
#import "SLMotorViewController.h"
#import "RocketMotor.h"
#import "SLDefinitions.h"

#define CELL_VIEW_HEIGHT 86
#define CELL_VIEW_WIDTH 140

@interface SLMotorTableViewController ()
@property (nonatomic, strong) NSDictionary *selectedMotorDict;
@property (nonatomic, strong) RocketMotor *selectedMotor;
@end

@implementation SLMotorTableViewController 

@synthesize motors = _motors;
@synthesize sectionKey = _sectionKey;
@synthesize selectedMotor = _selectedMotor;
@synthesize selectedMotorDict = _selectedMotorDict;
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{    
    return [self.motors count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.motors objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MotorCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSDictionary *motorDict = [[self.motors objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [motorDict objectForKey:NAME_KEY];
    cell.detailTextLabel.text = [motorDict objectForKey:MAN_KEY];
    NSString *path = [[NSBundle mainBundle] pathForResource:[motorDict objectForKey:MAN_KEY] ofType:@"png"];
    UIImage *theImage = [UIImage imageWithContentsOfFile:path];
    cell.imageView.image = theImage;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    // use the first object in the section to tell us what the header name should be
    if ([[self.motors objectAtIndex:section] count]!=0) {
        return [[[self.motors objectAtIndex:section] objectAtIndex:0] objectForKey:self.sectionKey];
    } else {
        return nil;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedMotorDict = [[self.motors objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    self.selectedMotor = [RocketMotor motorWithMotorDict:self.selectedMotorDict];
    [self.delegate sender:self didChangeRocketMotor:self.selectedMotor];
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    self.selectedMotorDict = [[self.motors objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    self.selectedMotor = [RocketMotor motorWithMotorDict:self.selectedMotorDict];
    [self.delegate sender:self didChangeRocketMotor:self.selectedMotor];
    [self performSegueWithIdentifier:@"motorDetailSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell *)sender{
    if ([segue.identifier isEqualToString:@"motorDetailSegue"]){
        [(SLMotorViewController *)segue.destinationViewController setMotor:self.selectedMotor];
        [segue.destinationViewController setTitle:self.selectedMotor.name];
    }
}

@end
