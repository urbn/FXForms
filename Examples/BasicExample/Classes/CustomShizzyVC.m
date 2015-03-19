//
//  CustomShizzyVC.m
//  BasicExample
//
//  Created by Joseph Ridenour on 3/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//


#import "CustomShizzyVC.h"
#import "FXForms.h"

@interface Login : NSObject <FXForm>
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@end
@implementation Login @end

@interface ForgotPass : NSObject <FXForm>
@property (nonatomic, copy) NSString *password;
@end
@implementation ForgotPass @end

@interface Reg1 : NSObject <FXForm>
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *birthDay;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *passwordConfirm;
@end
@implementation Reg1 @end



@interface URBNSpecialFormController : FXCollectionFormController

+ (NSDictionary *)formDiffFromForm:(id<FXForm>)fromForm toForm:(id<FXForm>)toForm;

@end


@implementation URBNSpecialFormController

+ (NSDictionary *)formDiffFromForm:(id<FXForm>)fromForm toForm:(id<FXForm>)toForm {
    
    FXFormController *fc1 = [[FXFormController alloc] init];
    fc1.form = fromForm;
    
    FXFormController *fc2 = [[FXFormController alloc] init];
    fc2.form = toForm;
    
    NSMutableArray *inserts = [NSMutableArray array];
    NSMutableArray *updates = [NSMutableArray array];
    NSMutableArray *deletes = [NSMutableArray array];
    
    
    // First we want to figure out what the deletes and updates are
    NSInteger section = 0, item = 0;
    for (FXFormSection *sec in fc1.sections) {
        
        for (FXFormField *f in sec.fields) {
            NSIndexPath *curIp = [NSIndexPath indexPathForItem:item inSection:section];
            
            // Check fc2 for this field
            if ([fc2 fieldForKey:f.key]) {
                NSIndexPath *otherIP = [fc2 indexPathForField:[fc2 fieldForKey:f.key]];
                if ([curIp isEqual:otherIP]) {
                    // No update
                }
                else {
                    [updates addObject:@{@"ip": otherIP, @"field": f, @"oldPath": curIp}];
                }
            }
            else {
                // This field is deleted.   Peace
                [deletes addObject:@{@"ip": curIp, @"field": f}];
            }
            item++;
        }
        section++;
    }
    
    section = 0, item = 0;
    for (FXFormSection *sec in fc2.sections) {
        
        for (FXFormField *f in sec.fields) {
            NSIndexPath *curIp = [NSIndexPath indexPathForItem:item inSection:section];
            
            // If field in fc2 is not in fc1, then we're inserting that field.
            if (![fc1 fieldForKey:f.key]) {
                [inserts addObject:@{@"ip": curIp, @"field": f}];
            }
            
            item++;
        }
        section++;
    }
    
    return NSDictionaryOfVariableBindings(inserts, updates, deletes);
}

@end


@implementation CustomShizzyVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissMe)];
    
    self.formController.form = [Login new];
}

- (void)dismissMe {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (void)performCollectionUpdatesWithForm:(id<FXForm>)form {
    
    NSDictionary *diffs = [URBNSpecialFormController formDiffFromForm:self.formController.form toForm:form];
    
    NSArray *updates = diffs[@"updates"];
    NSArray *deletes = diffs[@"deletes"];
    NSArray *inserts = diffs[@"inserts"];
    
    [self.collectionView performBatchUpdates:^{
        self.formController.form = form;
        
        if (deletes.count > 0)
            [self.collectionView deleteItemsAtIndexPaths:[deletes valueForKeyPath:@"@unionOfObjects.ip"]];
        if (inserts.count > 0) {
            [self.collectionView insertItemsAtIndexPaths:[inserts valueForKeyPath:@"@unionOfObjects.ip"]];
        }
        
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)loginForm:(id)sender {
    [self performCollectionUpdatesWithForm:[Login new]];
}

- (IBAction)forgotPass:(id)sender {
    [self performCollectionUpdatesWithForm:[ForgotPass new]];
}

- (IBAction)reg:(id)sender {
    [self performCollectionUpdatesWithForm:[Reg1 new]];
}

@end





