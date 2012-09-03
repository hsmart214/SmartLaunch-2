//
//  SLRocketPropertiesTVC.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import "SLRocketPropertiesTVC.h"
#import "SLDefinitions.h"

#define DELETE_BUTTON_INDEX 2

@interface SLRocketPropertiesTVC ()<UIScrollViewDelegate, UIActionSheetDelegate, UITableViewDelegate>

@property (weak, nonatomic) UIScrollView *scrollView;
@property (nonatomic, weak) UITextField *activeField;
@property (nonatomic, strong) Rocket *oldRocket;
@property (nonatomic, strong) NSArray *validMotorDiameters;
@property (weak, nonatomic) IBOutlet UIStepper *motorDiamStepper;

@end

@implementation SLRocketPropertiesTVC

@synthesize oldRocket = _oldRocket;
@synthesize rocket = _rocket;
@synthesize toolbar = _toolbar;
@synthesize delegate = _delegate;
@synthesize scrollView = _scrollView;
@synthesize activeField = _activeField;

@synthesize nameField;
@synthesize kitNameField;
@synthesize manField;
@synthesize massField;
@synthesize diamField;
@synthesize lenField;
@synthesize cdField;
@synthesize motorDiamLabel;
@synthesize massUnitsLabel;
@synthesize diamUnitsLabel;
@synthesize lenUnitsLabel;
@synthesize motorDiamUnitsLabel;
@synthesize cancelButton;
@synthesize saveButton;
@synthesize deleteButton;
@synthesize validMotorDiameters = _validMotorDiameters;
@synthesize motorDiamStepper;

- (NSArray *)validMotorDiameters{
    if (!_validMotorDiameters){
        _validMotorDiameters = [NSArray arrayWithObjects:
                                [NSNumber numberWithInteger:6],
                                [NSNumber numberWithInteger:13],
                                [NSNumber numberWithInteger:18],
                                [NSNumber numberWithInteger:24],
                                [NSNumber numberWithInteger:29],
                                [NSNumber numberWithInteger:38],
                                [NSNumber numberWithInteger:54],
                                [NSNumber numberWithInteger:66],
                                [NSNumber numberWithInteger:75],
                                [NSNumber numberWithInteger:98],
                                [NSNumber numberWithInteger:150],
                                nil];
    }
    return _validMotorDiameters;
}

- (BOOL)isValidRocket{
    BOOL valid = YES;
    valid = valid && ([self.nameField.text length] != 0);
    valid = valid && ([self.massField.text length] != 0);
    valid = valid && ([self.diamField.text length] != 0);
    valid = valid && ([self.motorDiamLabel.text length] != 0);
    valid = valid && ([self.cdField.text floatValue] > 0);
    return valid;
}

- (void)updateRocket{
    self.rocket.name = self.nameField.text;
    self.rocket.kitName = self.kitNameField.text;
    self.rocket.manufacturer = self.manField.text;
    self.rocket.mass = [SLUnitsConvertor metricStandardOf:
                        [NSNumber numberWithFloat:fabsf([self.massField.text floatValue])] forKey:MASS_UNIT_KEY];
    self.rocket.diameter = [SLUnitsConvertor metricStandardOf:
                            [NSNumber numberWithFloat:fabsf([self.diamField.text floatValue])] forKey:DIAM_UNIT_KEY];
    self.rocket.length = [SLUnitsConvertor metricStandardOf:
                          [NSNumber numberWithFloat:fabsf([self.lenField.text floatValue])] forKey:LENGTH_UNIT_KEY];
    self.rocket.cd = [NSNumber numberWithFloat:fabsf([self.cdField.text floatValue])];
    NSInteger motorDiam = [self.motorDiamLabel.text integerValue];
    self.rocket.motorSize = [NSNumber numberWithInteger:motorDiam];
    [self.saveButton setEnabled:[self isValidRocket]];
}

- (void)updateDisplay{
    self.nameField.text = self.rocket.name;
    self.kitNameField.text = self.rocket.kitName;
    self.manField.text = self.rocket.manufacturer;
    NSNumber *temp = [SLUnitsConvertor displayUnitsOf:self.rocket.mass forKey:MASS_UNIT_KEY];
    self.massField.text = [NSString stringWithFormat:@"%2.2f", [temp floatValue]];
    temp = [SLUnitsConvertor displayUnitsOf:self.rocket.diameter forKey:DIAM_UNIT_KEY];
    self.diamField.text = [NSString stringWithFormat:@"%2.2f", [temp floatValue]];
    temp = [SLUnitsConvertor displayUnitsOf:self.rocket.length forKey:LENGTH_UNIT_KEY];
    self.lenField.text = [NSString stringWithFormat:@"%2.2f", [temp floatValue]];
    self.cdField.text = [NSString stringWithFormat:@"%2.2f", [self.rocket.cd floatValue]];
    self.motorDiamLabel.text = [NSString stringWithFormat:@"%d", [self.rocket.motorSize integerValue]];
    self.motorDiamStepper.value = [self.rocket.motorSize integerValue];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    if (!_rocket){
        _rocket = [[Rocket alloc] init];
        // if we were not passed a Rocket* then we don't need the delete button (at index 2)
        NSMutableArray *items = [NSMutableArray array];
        for (NSInteger i = 0; i < [self.toolbar.items count]; i++){
            if (i != DELETE_BUTTON_INDEX) [items addObject:[self.toolbar.items objectAtIndex:i]];
        }
        self.toolbar.items = items;
        self.motorDiamStepper.value = [self.motorDiamStepper minimumValue];
        self.motorDiamLabel.text = [NSString stringWithFormat:@"%1.0f", self.motorDiamStepper.value];
        _rocket.motorSize = [NSNumber numberWithInteger:6];
    }else {
        self.oldRocket = [self.rocket copy];    // in case we need to delete this Rocket* later
    }
    
    [self registerForKeyboardNotifications];
    
    // set up the unit labels based on user preferences
    self.motorDiamUnitsLabel.text = [SLUnitsConvertor displayStringForKey:MOTOR_SIZE_UNIT_KEY];
    self.massUnitsLabel.text = [SLUnitsConvertor displayStringForKey:MASS_UNIT_KEY];
    self.lenUnitsLabel.text = [SLUnitsConvertor displayStringForKey:LENGTH_UNIT_KEY];
    self.diamUnitsLabel.text = [SLUnitsConvertor displayStringForKey:DIAM_UNIT_KEY];
    
    self.nameField.delegate = self;
    self.kitNameField.delegate = self;
    self.manField.delegate = self;
    self.massField.delegate = self;
    self.diamField.delegate = self;
    self.lenField.delegate = self;
    self.cdField.delegate = self;
    
    [self updateDisplay];
}

- (void)viewDidUnload
{
    [self setNameField:nil];
    [self setKitNameField:nil];
    [self setManField:nil];
    [self setMassField:nil];
    [self setDiamField:nil];
    [self setLenField:nil];
    [self setCdField:nil];
    [self setMassUnitsLabel:nil];
    [self setDiamUnitsLabel:nil];
    [self setLenUnitsLabel:nil];
    [self setCancelButton:nil];
    [self setSaveButton:nil];
    [self setCancelButton:nil];
    [self setSaveButton:nil];
    [self setScrollView:nil];
    [self setMotorDiamLabel:nil];
    [self setMotorDiamUnitsLabel:nil];
    [self setDeleteButton:nil];
    [self setToolbar:nil];
    [self setRocket:nil];
    [self setMotorDiamStepper:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return NO;
        //        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return NO;
    }
}


#pragma mark - UITextFieldDelegate methods

- (IBAction)textEditingDidBegin:(UITextField *)sender {
    self.activeField = sender;
}


- (IBAction)textEditingDidEnd:(UITextField *)sender {
    [sender resignFirstResponder];
    self.activeField = nil;
    [self updateRocket];
}

- (IBAction)textEditingDidEndOnExit:(UITextField *)sender {
    [self textEditingDidEnd:sender];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}



// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, kbSize.height);
        [self.scrollView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - UIStepper method

- (IBAction)motorDiameterChanged:(UIStepper *)sender {
    NSInteger mmt = [self.motorDiamLabel.text integerValue];
    float direction = sender.value - mmt;
    NSInteger newSize = 0;
    if (direction > 0){
        // increment motor size to next larger valid size
        for (int i=0; i < [self.validMotorDiameters count]; i++){
            if ([[self.validMotorDiameters objectAtIndex:i]integerValue] == mmt){
                newSize = [[self.validMotorDiameters objectAtIndex:i+1] integerValue];
                break;
            }
        }
    }else{
        // decrement motor size to next smaller valid size
        for (int i=0; i < [self.validMotorDiameters count]; i++){
            if ([[self.validMotorDiameters objectAtIndex:i]integerValue] == mmt){
                newSize = [[self.validMotorDiameters objectAtIndex:i-1] integerValue];
                break;
            }
        }
    }
    sender.value = newSize;
    self.motorDiamLabel.text = [NSString stringWithFormat:@"%d", newSize];
    [self updateRocket];
}

#pragma mark - Save/Delete/Cancel actions

- (IBAction)saveButtonPressed:(UIBarButtonItem *)sender {
    [self.delegate SLRocketPropertiesTVC: self savedRocket:self.rocket];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)deleteButtonPressed:(UIBarButtonItem *)sender {
    NSString *message = [NSString stringWithFormat:@"Delete %@?", self.rocket.name];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:message delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles: nil];
    [actionSheet showInView:self.view];
}


// pop back without saving
- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    if (self.oldRocket)[self.delegate SLRocketPropertiesTVC:self savedRocket:self.oldRocket];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == [actionSheet destructiveButtonIndex]){
        [self.delegate SLRocketPropertiesTVC:self deletedRocket:self.oldRocket];
        [self.navigationController popViewControllerAnimated:YES];
    }
    if (buttonIndex ==[actionSheet cancelButtonIndex]){
        // do nothing
    }
}

#pragma mark - UITableViewDelegate method

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
