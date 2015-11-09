//
//  SLAvatarTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/7/15.
//  Copyright © 2015 J. HOWARD SMART. All rights reserved.
//

#import "SLAvatarTVC.h"

@interface SLAvatarTVC ()

@property (nonatomic, strong) NSArray *avatarNames;

@end

@implementation SLAvatarTVC

-(NSArray *)avatarNames{
    if (!_avatarNames){
        _avatarNames = @[@"Goblin",
                         @"Patriot",
                         @"Sensor",
                         @"AlphaIII",
                         @"ArmyHawk",
                         @"Batray",
                         @"BigDaddy",
                         @"BigFizz",
                         @"Cowabunga",
                         @"Cricket",
                         @"DerRedMax",
                         @"FatBoy",
                         @"Jayhawk",
                         @"LilGoblin",
                         @"MartianTransport",
                         @"Mosquito",
                         @"NikeSmoke",
                         @"Phoenix",
                         @"Pike",
                         @"SeaWolf",
                         @"SportX",
                         @"Squat",
                         @"SuperDX3",
                         @"Tembo",
                         ];
    }
    return _avatarNames;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Avatar Cell" forIndexPath:indexPath];
    NSString *name = self.avatarNames[indexPath.row];
    cell.textLabel.text = name;
    cell.imageView.image = [UIImage imageNamed:name];
    if ([name isEqualToString:self.avatar]){
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }else{
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.delegate avatarTVC:self didPickAvatarNamed:self.avatarNames[indexPath.row ]];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.avatarNames count];
}

-(void)dealloc{
    self.avatarNames = nil;
    self.avatar = nil;
}

-(NSString *)description{
    return @"Avatar Chooser TVC";
}

@end
