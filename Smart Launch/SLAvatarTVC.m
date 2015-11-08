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
                         ];
    }
    return _avatarNames;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Avatar Cell" forIndexPath:indexPath];
    NSString *name = self.avatarNames[indexPath.row];
    cell.textLabel.text = name;
    cell.imageView.image = [UIImage imageNamed:name];
    return cell;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.avatarNames count];
}


@end
