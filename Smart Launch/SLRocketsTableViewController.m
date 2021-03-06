//
//  SLRocketsTableViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//


#import "SLRocketsTableViewController.h"

@interface SLRocketsTableViewController ()

@property (nonatomic, strong) NSMutableDictionary *rockets;
@property (nonatomic, strong) NSString *detailData;
@property (nonatomic, strong) NSMutableArray *rocketArray;
@property (nonatomic, strong) Rocket *selectedRocket;
@property (nonatomic, strong) id iCloudObserver;

@end

@implementation SLRocketsTableViewController

- (void)updateRocketArray{
    if ([self.rocketArray count]) [self.rocketArray removeAllObjects];
    NSArray *temp = [self.rockets allValues];
    temp = [temp sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *r1, NSDictionary *r2){
        return [r1[ROCKET_NAME_KEY] compare:r2[ROCKET_NAME_KEY]];
    }];
    for (NSDictionary *rocketPList in temp){
        [self.rocketArray addObject:[Rocket rocketWithRocketDict:rocketPList]];
    }
}

- (void)pushRocketFavorites{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    [defaults setObject:self.rockets forKey:FAVORITE_ROCKETS_KEY];
    [store setDictionary:self.rockets forKey:FAVORITE_ROCKETS_KEY];
    [defaults synchronize];
}

- (NSMutableArray *)rocketArray{
    if (!_rocketArray){
        _rocketArray = [NSMutableArray array];
    }
    return _rocketArray;
}

- (NSString *)detailData{
    if (!_detailData){
        _detailData = ROCKET_KITNAME_KEY;
    }
    return _detailData;
}

- (NSMutableDictionary *)rockets{
    if (!_rockets){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _rockets = [[defaults objectForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
        if (!_rockets || [_rockets count] == 0){     // If the rocket list is empty give them an example rocket
            _rockets = [NSMutableDictionary dictionary];
            Rocket *defaultRocket = [Rocket defaultRocket];
            _rockets[defaultRocket.name] = [defaultRocket rocketPropertyList];
            [defaults setObject:_rockets forKey:FAVORITE_ROCKETS_KEY];
            [defaults synchronize];
            [self updateRocketArray];
        }
    }
    return _rockets;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad{
    [super viewDidLoad];
    if (!self.splitViewController){
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }else{
        //self.tableView.backgroundColor = [SLCustomUI iPadBackgroundColor];
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_FOR_IPAD_MASTER_VC];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }
    [self updateRocketArray];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    
    __weak SLRocketsTableViewController *myWeakSelf = self;

    self.iCloudObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil queue:nil usingBlock:^(NSNotification *notification){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSArray *changedKeys = [[notification userInfo] objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        for (NSString *key in changedKeys) {
            [defaults setObject:[store objectForKey:key] forKey:key];       // right now this can only be the favorite rockets dictionary
        }
        [defaults synchronize];
        dispatch_async(dispatch_get_main_queue(), ^{
            myWeakSelf.rockets = [[defaults dictionaryForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
            [myWeakSelf updateRocketArray];
            [myWeakSelf.tableView reloadData];
        });
    }];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self.iCloudObserver];
    self.iCloudObserver = nil;
}

-(void)dealloc{
    self.rocketArray = nil;
    self.rockets = nil;
    self.selectedRocket = nil;
    self.detailData = nil;
    self.iCloudObserver = nil;
}

- (void)didReceiveMemoryWarning{
    self.rockets = nil;
    self.rocketArray = nil;
    [super didReceiveMemoryWarning];
}

#pragma mark - Seque action

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"editRocketSegue"]){
        [(SLRocketPropertiesTVC *)[segue destinationViewController] setRocket:self.selectedRocket];
        [(SLRocketPropertiesTVC *)[segue destinationViewController] setDelegate: self];
        [[segue destinationViewController] setTitle:self.selectedRocket.name];
    }
    if ([[segue identifier] isEqualToString:@"addRocketSegue"]){
        [(SLRocketPropertiesTVC *)[segue destinationViewController] setDelegate: self];
        [[segue destinationViewController] setTitle:NSLocalizedString(@"New Rocket", @"New Rocket (title)")];
    }
}

#pragma mark - SLRocketPropertiesTVCDelegate methods

- (void)SLRocketPropertiesTVC:(SLRocketPropertiesTVC *)sender savedRocket:(Rocket *)rocket{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSMutableDictionary *rocketFavorites = [[defaults objectForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
    if (!rocketFavorites) rocketFavorites = [NSMutableDictionary dictionary];
    rocketFavorites[rocket.name] = rocket.rocketPropertyList;
    [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    [store setDictionary:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    self.selectedRocket = rocket;
    self.rockets = rocketFavorites;
    [defaults synchronize];
    [self updateRocketArray];
    [self.tableView reloadData];
}

- (void)SLRocketPropertiesTVC:(SLRocketPropertiesTVC *)sender deletedRocket:(Rocket *)rocket{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSMutableDictionary *rocketFavorites = [[defaults objectForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
    if (!rocketFavorites||[rocketFavorites count]==0) return;
    [rocketFavorites removeObjectForKey:rocket.name];
    [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    [store setDictionary:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    [defaults synchronize];
    [self.rockets removeObjectForKey:rocket.name];
    [self updateRocketArray];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.rockets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"RocketCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    Rocket* cellRocket = (self.rocketArray)[indexPath.row];
    cell.textLabel.text = cellRocket.name;
    id detailInfo = [cellRocket rocketPropertyList][self.detailData];
    if ([detailInfo isKindOfClass:[NSString class]]){
        cell.detailTextLabel.text = detailInfo;
    } else {
        //cell.detailTextLabel.text = [NSString stringWithFormat:@"%1.2f m", [detailInfo floatValue]];
        cell.detailTextLabel.text = nil;
    }
    cell.imageView.image = [UIImage imageNamed:cellRocket.avatar];
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.rockets removeObjectForKey:(((Rocket *)(self.rocketArray)[indexPath.row]).name)];
        [self updateRocketArray];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self pushRocketFavorites];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.selectedRocket = (self.rocketArray)[indexPath.row];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.selectedRocket rocketPropertyList] forKey:SELECTED_ROCKET_KEY];
    [defaults synchronize];
    [self.delegate sender:self didChangeRocket:self.selectedRocket];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    self.selectedRocket = (self.rocketArray)[indexPath.row];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.selectedRocket rocketPropertyList] forKey:SELECTED_ROCKET_KEY];
    [defaults synchronize];
    [self.delegate sender:self didChangeRocket:self.selectedRocket];
    [self performSegueWithIdentifier:@"editRocketSegue" sender:self];
}

-(NSString *)description{
    return @"RocketsTVC";
}

@end
