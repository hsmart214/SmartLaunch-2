//
//  SLInformationTVC.m
//  Smart Launch
//
//  Created by J. Howard Smart on 7/3/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLInformationTVC.h"


@interface SLInformationTVC ()
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation SLInformationTVC

- (IBAction)userDidPressDone:(UIBarButtonItem *)sender {
    [self.delegate dismissModalViewController];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.infoTextView flashScrollIndicators];
    if (self.splitViewController){
        //self.tableView.backgroundColor = [SLCustomUI iPadBackgroundColor];
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_FOR_IPAD_MASTER_VC];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }else{
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        self.tableView.backgroundView = backgroundView;
        self.tableView.backgroundColor = [UIColor clearColor];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.infoTextView flashScrollIndicators];
}

- (void)requestNewMotorList{
    [self.spinner startAnimating];
    dispatch_queue_t myQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(myQueue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger currentVersion = [defaults integerForKey:MOTOR_FILE_VERSION_KEY];  //nil if never used, resulting in 0
        NSURL *motorFileWWWURL = [NSURL URLWithString:MOTORS_WWW_URL];
        NSURL *motorFileVersionWWWURL = [NSURL URLWithString:MOTORS_VERSION_WWW_URL];
        NSError *err = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        });
        NSStringEncoding enc;
        NSString *version = [NSString stringWithContentsOfURL:motorFileVersionWWWURL usedEncoding:&enc error:&err];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });        if (err){
            NSLog(@"\nError reading Motor version from mySmartSoftware.com");
            NSLog(@"%@", err.debugDescription);
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Motor List Update", @"Motor List Update")
                                                                            message:NSLocalizedString(@"Unable to contact website.", @"Unable to contact website.")
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *act){
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   [alert.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                                               });
                                                           }];
            [alert addAction:action];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
        NSUInteger versionNumber = [version integerValue];
        if (versionNumber > currentVersion){
            // nuke the cache
            NSURL *cacheURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask]lastObject];
            NSURL *motorCacheURL = [cacheURL URLByAppendingPathComponent:MOTOR_CACHE_FILENAME];
            if ([[NSFileManager defaultManager]fileExistsAtPath:[motorCacheURL path]]){
                [[NSFileManager defaultManager] removeItemAtURL:motorCacheURL error:nil];
            }
            // get the new data from the website
            NSURL *dataURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            NSURL *motorFileURL = [dataURL URLByAppendingPathComponent:MOTOR_DATA_FILENAME];
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            });
            NSString *allMotors = [NSString stringWithContentsOfURL:motorFileWWWURL encoding:NSUTF8StringEncoding error:&err];
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            });
            if (err){
                NSLog(@"Error reading Motor data file from mySmartSoftware.com");
            }else{
                if ([[NSFileManager defaultManager]fileExistsAtPath:[motorFileURL path]]){
                    [[NSFileManager defaultManager] removeItemAtURL:motorFileURL error:nil];
                }
                [allMotors writeToURL:motorFileURL atomically:YES encoding:NSUTF8StringEncoding error:&err];
                if (err){
                    NSLog(@"Error writing Motor data file to data directory.");
                }else{
                    [defaults setInteger:versionNumber forKey:MOTOR_FILE_VERSION_KEY];
                    [defaults synchronize];
                    // TODO: localize this message
                    NSString *message = [NSString stringWithFormat:@"Motor list updated from v.%ld to v.%ld", (long)currentVersion, (unsigned long)versionNumber];
                    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Motor List Update", @"Motor List Update")
                                                                                    message:message
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction *act){
                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                           [alert.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                                                       });
                                                                   }];
                    [alert addAction:action];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentViewController:alert animated:YES completion:nil];
                    });
                }
            }
        }else{
            // TODO: localize this again
            NSString *message = [NSString stringWithFormat:@"Motor list is up to date: version %ld", (long)currentVersion];
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Motor List Update", @"Motor List Update")
                                                                            message:message
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *act){
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   [alert.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                                               });
                                                           }];
            [alert addAction:action];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
        });
    });
}

#pragma mark - Table View Controller Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 2){
        // If a thread is running to check for motors already, the spinner will be visible
        if ([self.spinner isHidden]) [self requestNewMotorList];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return [SLCustomUI headerHeight];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    NSString *headerText;
    if (section == 0){
        headerText = NSLocalizedString(@"Information", @"Information");
    }else{  // must be last section - there are only two
        headerText = NSLocalizedString(@"Settings", @"Settings");
    }
    UILabel *headerLabel = [[UILabel alloc] init];
    [headerLabel setTextColor:[SLCustomUI headerTextColor]];
    [headerLabel setBackgroundColor:self.tableView.backgroundColor];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setText:headerText];
    [headerLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
    
    return headerLabel;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue destinationViewController] respondsToSelector:@selector(setDelegate:)]){
        [[segue destinationViewController] performSelector:@selector(setDelegate:) withObject:self.delegate];
    }
}

#pragma mark - SLModalPresenterDelegate method

- (void)dismissModalVC:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSString *)description{
    return @"InformationTVC";
}


@end
