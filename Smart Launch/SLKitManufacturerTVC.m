//
//  SLKitManufacturerTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 12/10/14.
//  Copyright (c) 2014 J. HOWARD SMART. All rights reserved.
//

#import "SLKitManufacturerTVC.h"

@interface SLKitManufacturerTVC ()

@property (nonatomic, strong) NSArray *kits;

@end

@implementation SLKitManufacturerTVC

- (NSArray *)kits{
    if (!_kits){
        NSBundle *bundle = [NSBundle mainBundle];
        NSURL *url =[bundle URLForResource:KIT_PLIST_FILENAME withExtension:@"plist"];
        NSMutableArray *mutableKits = [[NSArray arrayWithContentsOfFile: [url path]] mutableCopy];
        NSInteger total = [mutableKits count];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.kits count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"manCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSDictionary *manDict = self.kits[indexPath.row];
    // Configure the cell...
    NSString *man = manDict[ROCKET_MAN_KEY];
    cell.textLabel.text = man;
    cell.imageView.image = [UIImage imageNamed:man];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu Kits", (unsigned long)[manDict[MANUFACTURED_KITS_KEY] count]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Prepare for Segue


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell *)sender{
    SLKitsTVC *dest = [segue destinationViewController];
    NSUInteger row = [self.tableView indexPathForCell:sender].row;
    NSArray *singleManKits = @[self.kits[row]];
    dest.kits = singleManKits;
    dest.delegate = self.delegate;
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
