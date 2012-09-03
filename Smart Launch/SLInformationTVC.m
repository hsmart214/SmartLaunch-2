//
//  SLInformationTVC.m
//  Snoopy
//
//  Created by J. Howard Smart on 7/3/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
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

- (void)viewDidUnload
{
    [self setDoneButton:nil];
    [self setInfoTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section != 1) return;
    if (indexPath.row == 0){
//        [self performSegueWithIdentifier:@"unitsSegue" sender:self];
    }
    if (indexPath.row == 1){
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        NSString *message = [NSString stringWithFormat:@"Delete all saved Rockets?"];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:message delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles: nil];
        [actionSheet showInView:self.view];
    } else if (indexPath.row == 2){
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:ALL_MOTORS_KEY];
        [defaults synchronize];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"unitsSegue"]) {
//        [segue.destinationViewController setDelegate:self.delegate];
//        [segue.destinationViewController setPresenter:self];
    }
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
