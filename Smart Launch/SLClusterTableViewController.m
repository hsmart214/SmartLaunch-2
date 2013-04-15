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

@interface SLClusterTableViewController ()

@property (nonatomic, strong) NSMutableArray *clusters;
@property (nonatomic, strong) id iCloudObserver;

@end

@implementation SLClusterTableViewController

- (IBAction)createNewCluster:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"ClusterBuildSegue" sender:sender];
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
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%1.0f%% %@", impulseFrac*100, [cluster nextImpulseClass]];
    NSString *digit = [NSString stringWithFormat:@"%d", [cluster.motors count]];
    NSString *fileName = [@"Cluster" stringByAppendingString:digit];
    cell.imageView.image = [UIImage imageNamed:fileName];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.clusters removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"ClusterBuildSegue"]){
        SLClusterMotorBuildViewController *dest = segue.destinationViewController;
        dest.delegate = self;
        if ([sender isKindOfClass:[UITableViewCell class]]){
            NSInteger i = [self.tableView indexPathForCell:sender].row;
            dest.title = [self.clusters[i] description];
            dest.clusterMotor = self.clusters[i];
        }else{
            dest.title = @"New Cluster";
        }
    }
}

#pragma mark - SLClusterListDelegate method

-(void)changedClusterMotor:(SLClusterMotor *)clusterMotor sender:(id)sender{
    //Does it exist already? - remove it
    for (SLClusterMotor *cluster in self.clusters){
        if ([cluster.name isEqualToString:clusterMotor.name]){
            [self.clusters removeObject:cluster];
            break;
        }
    }
    // whether or not it was there before, add it in
    [self.clusters addObject:clusterMotor];
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
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    self.clusters = [defaults mutableArrayValueForKey:FAVORITE_CLUSTERS_KEY];
    self.iCloudObserver = [[NSNotificationCenter defaultCenter]
        addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil
                                                                                     queue:nil
                                                                                usingBlock:^(NSNotification *notification){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *changedKeys = [[notification userInfo] objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        for (NSString *key in changedKeys) {
            [defaults setObject:[store objectForKey:key] forKey:key];
        }
        [defaults synchronize];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.clusters = [defaults mutableArrayValueForKey:FAVORITE_CLUSTERS_KEY];
            [self.tableView reloadData];
        });
    }];
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    [defaults setObject:self.clusters forKey:FAVORITE_CLUSTERS_KEY];
    [store setArray:self.clusters forKey:FAVORITE_CLUSTERS_KEY];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] removeObserver:self.iCloudObserver];
    self.iCloudObserver = nil;
}

@end
