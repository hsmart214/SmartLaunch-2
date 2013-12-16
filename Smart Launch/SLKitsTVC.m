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

@property (nonatomic, strong) NSArray *kits;
@property (nonatomic, weak) UIPopoverController *popover;

@end

@implementation SLKitsTVC



- (NSArray *)kits{
    if (!_kits){
        NSBundle *bundle = [NSBundle mainBundle];
        NSURL *url =[bundle URLForResource:KIT_PLIST_FILENAME withExtension:@"plist"];
        NSMutableArray *mutableKits = [[NSArray arrayWithContentsOfFile: [url path]] mutableCopy];
        int total = [mutableKits count];
        for (int i = 0; i < total; i++){
            NSMutableDictionary *dict = [mutableKits[i] mutableCopy];
            NSArray *arr = dict[MANUFACTURED_KITS_KEY];
            NSArray *sorted = [arr sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
                NSString *name1 = ((NSDictionary *)obj1)[ROCKET_KITNAME_KEY];
                NSString *name2 = ((NSDictionary *)obj2)[ROCKET_KITNAME_KEY];
                if ([name1 compare:name2 options:NSCaseInsensitiveSearch] == NSOrderedSame){
                    return [((NSDictionary *)obj1)[ROCKET_DIAM_KEY] floatValue] > [((NSDictionary *)obj2)[ROCKET_DIAM_KEY] floatValue];
                }else{
                    return [name1 compare:name2 options:NSCaseInsensitiveSearch];
                }
            }];
            dict[MANUFACTURED_KITS_KEY] = sorted;
            mutableKits[i] = dict;
        }
        _kits = [mutableKits copy];
    }
    return _kits;
}

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
    cell.motorSizeLabel.text = [NSString stringWithFormat:@"%d mm", [kitDict[ROCKET_MOTORSIZE_KEY] integerValue]];
    float mass = [SLUnitsConvertor displayUnitsOf:[kitDict[ROCKET_MASS_KEY] floatValue] forKey:MASS_UNIT_KEY];
    cell.massLabel.text = [NSString stringWithFormat:@"%1.1f %@", mass, [SLUnitsConvertor displayStringForKey:MASS_UNIT_KEY]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.delegate SLKitTVC:self didChooseCommercialKit:self.kits[indexPath.section][MANUFACTURED_KITS_KEY][indexPath.row]];
    [self.navigationController popViewControllerAnimated:YES];
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
}

#pragma mark - View Life Cycle

- (void)viewDidLoad{
    [super viewDidLoad];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:BACKGROUND_IMAGE_FILENAME]];
}

- (void)didReceiveMemoryWarning{
    self.kits = nil;
}

- (void)dealloc{
    self.kits = nil;
}

@end
