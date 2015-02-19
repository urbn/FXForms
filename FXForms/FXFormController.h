//
//  FXFormController.h
//  BasicExample
//
//  Created by Joseph Ridenour on 2/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXFormsProtocols.h"

@class FXFormField;

@interface FXFormController : NSObject

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) FXFormController *parentFormController;
@property (nonatomic, weak) id<FXFormControllerDelegate> delegate;
@property (nonatomic, strong) id<FXForm> form;

@property (nonatomic, copy) NSArray *sections;

- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfFieldsInSection:(NSUInteger)section;
- (FXFormField *)fieldForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForField:(FXFormField *)field;
- (void)enumerateFieldsWithBlock:(void (^)(FXFormField *field, NSIndexPath *indexPath))block;

- (Class)cellClassForField:(FXFormField *)field;
- (void)registerDefaultFieldCellClass:(Class)cellClass;
- (void)registerCellClass:(Class)cellClass forFieldType:(NSString *)fieldType;
- (void)registerCellClass:(Class)cellClass forFieldClass:(Class)fieldClass;

- (Class)viewControllerClassForField:(FXFormField *)field;
- (void)registerDefaultViewControllerClass:(Class)controllerClass;
- (void)registerViewControllerClass:(Class)controllerClass forFieldType:(NSString *)fieldType;
- (void)registerViewControllerClass:(Class)controllerClass forFieldClass:(Class)fieldClass;

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)performAction:(SEL)selector withSender:(id)sender;

@end


@interface FXFormViewController : UIViewController <FXFormFieldViewController, FXFormControllerDelegate>

@property (nonatomic, readonly) FXFormController *formController;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end
