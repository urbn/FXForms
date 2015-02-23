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

@property (nonatomic, strong) FXFormController *parentFormController;
@property (nonatomic, weak) id<FXFormControllerDelegate> delegate;
@property (nonatomic, strong) id<FXForm> form;

@property (nonatomic, copy) NSArray *sections;

// DataSource Methods
- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfFieldsInSection:(NSUInteger)section;
- (FXFormField *)fieldForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForField:(FXFormField *)field;
- (id<FXFormFieldCell>)cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)enumerateFieldsWithBlock:(void (^)(FXFormField *field, NSIndexPath *indexPath))block;

// Cell Registration
- (Class)cellClassForField:(FXFormField *)field;
- (void)registerDefaultFieldCellClass:(Class)cellClass;
- (void)registerCellClass:(Class)cellClass forFieldType:(NSString *)fieldType;
- (void)registerCellClass:(Class)cellClass forFieldClass:(Class)fieldClass;

// ViewController registration
- (Class)viewControllerClassForField:(FXFormField *)field;
- (void)registerDefaultViewControllerClass:(Class)controllerClass;
- (void)registerViewControllerClass:(Class)controllerClass forFieldType:(NSString *)fieldType;
- (void)registerViewControllerClass:(Class)controllerClass forFieldClass:(Class)fieldClass;

// Actions
- (void)performUpdates:(void(^)())updatesBlock withCompletion:(void(^)())completion;

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition;
- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths;
- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)performAction:(SEL)selector withSender:(id)sender;

@end
