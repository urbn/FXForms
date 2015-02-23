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
    FXFormCollectionViewController *cvc = [[FXFormCollectionViewController alloc] init];
    cvc.formController.form = [[RootForm alloc] init];
    [self presetnFormVC:cvc];
}

@end
