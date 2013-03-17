//
//  SLInformationTVC.m
//  Smart Launch
//
//  Created by J. Howard Smart on 7/3/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLInformationTVC.h"


@interface SLInformationTVC ()<UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIAlertView *alert;

@end

@implementation SLInformationTVC

- (IBAction)userDidPressDone:(UIBarButtonItem *)sender {
    [self.delegate dismissModalViewController];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.infoTextView flashScrollIndicators];
    if (self.splitViewController) return;
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    NSString *backgroundFileName = [[NSBundle mainBundle] pathForResource: BACKGROUND_IMAGE_FILENAME ofType:@"png"];
    UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:backgroundFileName];
    [backgroundView setImage:backgroundImage];
    self.tableView.backgroundView = backgroundView;

}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)requestNewMotorList{
    [self.spinner startAnimating];
    dispatch_queue_t myQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(myQueue, ^(void){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger currentVersion = [defaults integerForKey:MOTOR_FILE_VERSION_KEY];  //nil if never used, resulting in 0
        NSURL *motorFileWWWURL = [NSURL URLWithString:MOTORS_WWW_URL];
        NSURL *motorFileVersionWWWURL = [NSURL URLWithString:MOTORS_VERSION_WWW_URL];
        NSError *err = nil;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSString *version = [NSString stringWithContentsOfURL:motorFileVersionWWWURL encoding:NSUTF8StringEncoding error:&err];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        if (err){
            NSLog(@"Error reading Motor version from mySmartSoftware.com");
            self.alert = [[UIAlertView alloc]initWithTitle:@"Motor List Update" message:@"Unable to contact website." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.alert show];
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
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            NSString *allMotors = [NSString stringWithContentsOfURL:motorFileWWWURL encoding:NSUTF8StringEncoding error:&err];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
                    self.alert = [[UIAlertView alloc]initWithTitle:@"Motor List Update" message:@"Your motor list has been updated." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.alert show];
                    });
                }
            }
        }else{
            self.alert = [[UIAlertView alloc]initWithTitle:@"Motor List Update" message:@"Your motor list is current." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.alert show];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
        });
    });
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 2){
        // If a thread is running to check for motors already, the spinner will be visible
        if ([self.spinner isHidden]) [self requestNewMotorList];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
}

#pragma mark - SLModalPresenterDelegate method

- (void)dismissModalVC:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlerViewDelegate method

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
}

#pragma mark - UIActionSheet delegate method

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == [actionSheet destructiveButtonIndex]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        [defaults setNilValueForKey:FAVORITE_ROCKETS_KEY];
        [store setNilValueForKey:FAVORITE_ROCKETS_KEY];
        [defaults synchronize];
    }
    if (buttonIndex ==[actionSheet cancelButtonIndex]){
        // do nothing
    }
}


- (void)viewWillDisappear:(BOOL)animated{
    [self.alert dismissWithClickedButtonIndex:0 animated:NO];
    self.alert = nil;
}

@end
