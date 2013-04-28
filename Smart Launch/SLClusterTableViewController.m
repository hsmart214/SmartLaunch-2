//
//  SLClusterTableViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterTableViewController.h"
#import "SLClusterMotorBuildViewController.h"
#import "SLClusterMotor.h"

@implementation SLClusterTableViewController

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.motorLoadouts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ClusterMotorCell" forIndexPath:indexPath];
    SLClusterMotor *cluster = [[SLClusterMotor alloc] initWithMotorLoadout:self.motorLoadouts[indexPath.row]];
    cell.textLabel.text = [cluster description];
    cell.detailTextLabel.text = cluster.fractionalImpulseClass;
    NSString *digit = [NSString stringWithFormat:@"%d", cluster.motorCount];
    NSString *fileName = [@"Cluster" stringByAppendingString:digit];
    cell.imageView.image = [UIImage imageNamed:fileName];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.clusterDelegate deleteSavedMotorLoadoutAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }   
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.clusterDelegate replaceMotorLoadoutPlist:self.motorLoadouts[indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - View Life Cycle

-(void)viewDidLoad{
    [super viewDidLoad];
    if (!self.splitViewController){
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }else{
        self.tableView.backgroundColor = [SLCustomUI iPadBackgroundColor];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

@end
