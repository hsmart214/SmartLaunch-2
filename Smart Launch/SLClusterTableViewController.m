//
//  SLClusterTableViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterTableViewController.h"
#import "SLClusterMotor.h"

@interface SLClusterTableViewController ()

@property (nonatomic, strong) NSMutableArray *clusters;

@end

@implementation SLClusterTableViewController

-(void)viewDidLoad{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    self.clusters = [[defaults arrayForKey:FAVORITE_CLUSTERS_KEY] mutableCopy];
    // Need to add iCloud support for this
}

-(NSMutableArray *)clusters{
    if (!_clusters){
        _clusters = [NSMutableArray array];
    }
    return _clusters;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.clusters count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ClusterMotorCell" forIndexPath:indexPath];
    SLClusterMotor *cluster = self.clusters[indexPath.row];
    cell.textLabel.text = cluster.name;
    float impulseFrac = [cluster fractionOfImpulseClass];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%2.0f%% %@", impulseFrac, [cluster nextImpulseClass]];
    NSString *digit = [NSString stringWithFormat:@"%d", [cluster.motors count]];
    NSString *fileName = [@"Cluster" stringByAppendingString:digit];
    cell.imageView.image = [UIImage imageNamed:fileName];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.clusters removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
