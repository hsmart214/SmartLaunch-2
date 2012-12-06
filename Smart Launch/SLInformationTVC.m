//
//  SLInformationTVC.m
//  Launch Smart
//
//  Created by J. Howard Smart on 7/3/12.
//  Copyright (c) 2012 mySmartSoftware. All rights reserved.
//

#import "SLInformationTVC.h"

@interface SLInformationTVC ()
@property (weak, nonatomic) IBOutlet UITableView *doneButton;
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;

@end

@implementation SLInformationTVC
@synthesize doneButton = _doneButton;
@synthesize infoTextView = _infoTextView;

@synthesize delegate = _delegate;

- (IBAction)userDidPressDone:(UIBarButtonItem *)sender {
    [self.delegate dismissModalViewController];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.infoTextView flashScrollIndicators];
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

- (void)viewDidUnload
{
    [self setDoneButton:nil];
    [self setInfoTextView:nil];
    self.delegate = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 2){
        NSURL *cacheURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *motorFileURL = [cacheURL URLByAppendingPathComponent:MOTOR_CACHE_FILENAME];
        if ([[NSFileManager defaultManager]fileExistsAtPath:[motorFileURL path]]){
            [[NSFileManager defaultManager] removeItemAtURL:motorFileURL error:nil];
        }

    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
}

#pragma mark - SLModalPresenterDelegate method

- (void)dismissModalVC:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIActionSheet delegate method

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == [actionSheet destructiveButtonIndex]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:nil forKey:FAVORITE_ROCKETS_KEY];
        [defaults synchronize];
    }
    if (buttonIndex ==[actionSheet cancelButtonIndex]){
        // do nothing
    }
}


@end
