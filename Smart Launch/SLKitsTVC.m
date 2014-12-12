//
//  SLKitsTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 9/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLKitsTVC.h"
#import "SLUnitsConvertor.h"
#import "SLKitCell.h"

@interface SLKitsTVC ()


@property (nonatomic, weak) UIPopoverController *popover;

@end

@implementation SLKitsTVC

#pragma mark - Table view data source
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return [self headerViewForSection:section];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [self.kits count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.kits[section][MANUFACTURED_KITS_KEY] count];
}

- (UITableViewHeaderFooterView *)headerViewForSection:(NSInteger)section{
    UITableViewHeaderFooterView *hfview = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"HFView"];
    if (!hfview){
        hfview = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"HFView"];
        //        [hfview setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    
    NSString *manufacturer = self.kits[section][ROCKET_MAN_KEY];
    UIView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:manufacturer]];
    if ([hfview.contentView.subviews count]){
        [hfview.contentView.subviews[0] removeFromSuperview];
    }
    [hfview.contentView addSubview:logoView];
    [hfview.contentView.subviews[0] setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [hfview.contentView.subviews[0] setCenter:CGPointMake(hfview.bounds.size.width / 2, [self tableView:self.tableView heightForHeaderInSection:section] / 2)];
    return hfview;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"kitCell";
    SLKitCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSDictionary *kitDict = self.kits[indexPath.section][MANUFACTURED_KITS_KEY][indexPath.row];
    // Configure the cell...
    cell.nameLabel.text = kitDict[ROCKET_KITNAME_KEY];
    cell.diameterLabel.text = [NSString stringWithFormat:@"%1.1f inch",[kitDict[ROCKET_DIAM_KEY] floatValue] * 12 * FEET_PER_METER];
    cell.motorSizeLabel.text = [NSString stringWithFormat:@"%ld mm", (long)[kitDict[ROCKET_MOTORSIZE_KEY] integerValue]];
    float mass = [SLUnitsConvertor displayUnitsOf:[kitDict[ROCKET_MASS_KEY] floatValue] forKey:MASS_UNIT_KEY];
    cell.massLabel.text = [NSString stringWithFormat:@"%1.1f %@", mass, [SLUnitsConvertor displayStringForKey:MASS_UNIT_KEY]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.delegate SLKitTVC:self didChooseCommercialKit:self.kits[indexPath.section][MANUFACTURED_KITS_KEY][indexPath.row]];
    //[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Prepare for Segue

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    return (!self.popover);
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    //the current implementation only segues to the popover.
    //this will need to change if I implement unwinding
    if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]])
        self.popover = (UIPopoverController *)([(UIStoryboardPopoverSegue *)segue popoverController]);
    if ([segue.identifier isEqualToString:@"choseKit Segue"]){
        
    }
}

#pragma mark - View Life Cycle

- (void)viewDidLoad{
    [super viewDidLoad];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:BACKGROUND_IMAGE_FILENAME]];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    self.kits = nil;
}

- (void)dealloc{
    self.kits = nil;
}

@end
