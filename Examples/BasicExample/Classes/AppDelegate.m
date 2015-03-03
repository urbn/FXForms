//
//  AppDelegate.m
//  BasicExample
//
//  Created by Nick Lockwood on 04/02/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "AppDelegate.h"
#import "RootFormViewController.h"
#import "FXTableFormController.h"
#import "FXCollectionFormController.h"
#import "RootForm.h"
#import "FXFormViews.h"


@implementation AppDelegate

- (void)cancelForm {
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)presetnFormVC:(UIViewController <FXFormFieldViewController>*)controller {
    controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelForm)];
    [self.window.rootViewController presentViewController:[[UINavigationController alloc] initWithRootViewController:controller] animated:YES completion:nil];
}

- (IBAction)showTableVersion {
    FXFormTableViewController *tvc = [[FXFormTableViewController alloc] init];
    tvc.formController.form = [[RootForm alloc] init];
    [self presetnFormVC:tvc];
}

- (IBAction)showCollectionVersion {
    [[FXFormTextFieldView appearance] setTextAlignment:NSTextAlignmentLeft];
    FXFormCollectionViewController *cvc = [[FXFormCollectionViewController alloc] init];
    cvc.formController.form = [[RootForm alloc] init];
    [self presetnFormVC:cvc];
}


- (void)submitLoginForm
{
    //now we can display a form value in our alert
    [[[UIAlertView alloc] initWithTitle:@"Login Form Submitted"
                                message:nil
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
}

- (void)submitRegistrationForm:(UITableViewCell<FXFormFieldCell> *)cell
{
    //we can lookup the form from the cell if we want, like this:
    RegistrationForm *form = cell.field.form;
    
    //we can then perform validation, etc
    if (form.agreedToTerms)
    {
        [[[UIAlertView alloc] initWithTitle:@"Login Form Submitted"
                                    message:nil
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:@"OK", nil] show];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"User Error"
                                    message:@"Please agree to the terms and conditions before proceeding"
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:@"Yes Sir!", nil] show];
    }
}

@end
