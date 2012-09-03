//
//  SLRocketsTableViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import "SLRocketsTableViewController.h"
#import "SLDefinitions.h"

@interface SLRocketsTableViewController ()

@property (nonatomic, strong) NSMutableDictionary *rockets;
@property (nonatomic, strong) NSString *detailData;
@property (nonatomic, strong) NSMutableArray *rocketArray;
@property (nonatomic, strong) Rocket *selectedRocket;

@end

@implementation SLRocketsTableViewController

@synthesize selectedRocket = _selectedRocket;
@synthesize rockets = _rockets;
@synthesize detailData = _detailData;
@synthesize rocketArray = _rocketArray;
@synthesize delegate = _delegate;

- (void)updateRocketArray{
    if ([self.rocketArray count]) [self.rocketArray removeAllObjects];
    NSArray *temp = [self.rockets allValues];
    for (NSDictionary *rocketPList in temp){
        [self.rocketArray addObject:[Rocket rocketWithRocketDict:rocketPList]];
    }
}

- (void)pushRocketFavorites{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.rockets copy] forKey:FAVORITE_ROCKETS_KEY];
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
            NSDictionary *alphaPList = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"Alpha", ROCKET_NAME_KEY,
                                   @"Alpha III", ROCKET_KITNAME_KEY,
                                   @"Estes", ROCKET_MAN_KEY,
                                   [NSNumber numberWithFloat:0.02479], ROCKET_DIAM_KEY,
                                   [NSNumber numberWithFloat:0.2794], ROCKET_LENGTH_KEY,
                                   [NSNumber numberWithFloat:0.034], ROCKET_MASS_KEY,
                                   [NSNumber numberWithInteger:18], ROCKET_MOTORSIZE_KEY,
                                   [NSNumber numberWithFloat:DEFAULT_CD], ROCKET_CD_KEY, nil];
            [_rockets setObject:alphaPList forKey:@"Alpha"];
            [defaults setObject:_rockets forKey:FAVORITE_ROCKETS_KEY];
            [defaults synchronize];
        }
    }
    return _rockets;
}

//- (id)initWithStyle:(UITableViewStyle)style{
//    self = [super initWithStyle:style];
//    return self;
//}

- (void)viewDidLoad{
    [super viewDidLoad];
    [self updateRocketArray];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewDidUnload{
    self.rocketArray = nil;
    self.rockets = nil;
    self.selectedRocket = nil;
    self.detailData = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
        [[segue destinationViewController] setTitle:@"New Rocket"];
    }
}

#pragma mark - LSRViewControllerDelegate methods

- (void)SLRocketPropertiesTVC:(SLRocketPropertiesTVC *)sender savedRocket:(Rocket *)rocket{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *rocketFavorites = [[defaults objectForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
    if (!rocketFavorites) rocketFavorites = [NSMutableDictionary dictionary];
    [rocketFavorites setObject:rocket.rocketPropertyList forKey:rocket.name];
    [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
    self.selectedRocket = rocket;
    self.rockets = rocketFavorites;
    [defaults synchronize];
    [self updateRocketArray];
    [self.tableView reloadData];
}

- (void)SLRocketPropertiesTVC:(SLRocketPropertiesTVC *)sender deletedRocket:(Rocket *)rocket{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *rocketFavorites = [[defaults objectForKey:FAVORITE_ROCKETS_KEY] mutableCopy];
    if (!rocketFavorites) return;
    if ([rocketFavorites count]==0) return;
    [rocketFavorites removeObjectForKey:rocket.name];
    [defaults setObject:rocketFavorites forKey:FAVORITE_ROCKETS_KEY];
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
    Rocket* cellRocket = [self.rocketArray objectAtIndex:indexPath.row];
    cell.textLabel.text = cellRocket.name;
    id detailInfo = [[cellRocket rocketPropertyList] objectForKey:self.detailData];
    if ([detailInfo isKindOfClass:[NSString class]]){
        cell.detailTextLabel.text = detailInfo;
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%1.2f m", [detailInfo floatValue]];
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.rockets removeObjectForKey:(((Rocket *)[self.rocketArray objectAtIndex:indexPath.row]).name)];
        [self updateRocketArray];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self pushRocketFavorites];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.selectedRocket = [self.rocketArray objectAtIndex:indexPath.row];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.selectedRocket rocketPropertyList] forKey:SELECTED_ROCKET_KEY];
    [defaults synchronize];
    [self.delegate sender:self didChangeRocket:self.selectedRocket];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    self.selectedRocket = [self.rocketArray objectAtIndex:indexPath.row];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.selectedRocket rocketPropertyList] forKey:SELECTED_ROCKET_KEY];
    [defaults synchronize];
    [self.delegate sender:self didChangeRocket:self.selectedRocket];
    [self performSegueWithIdentifier:@"editRocketSegue" sender:self];
}

@end
