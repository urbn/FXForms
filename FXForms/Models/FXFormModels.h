//
//  FXFormModels.h
//  BasicExample
//
//  Created by Joseph Ridenour on 2/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXFormsProtocols.h"

@class FXFormField, FXFormController;


@interface FXTemplateForm : NSObject <FXForm>
- (instancetype)initWithField:(FXFormField *)field;

@property (nonatomic, strong) FXFormField *field;
@property (nonatomic, strong) NSMutableArray *fields;
@property (nonatomic, strong) NSMutableArray *values;

@end

@interface FXOptionsForm : NSObject <FXForm>

- (instancetype)initWithField:(FXFormField *)field;

@property (nonatomic, strong) FXFormField *field;
@property (nonatomic, strong) NSArray *fields;

@end

@interface FXFormSection : NSObject


+ (NSArray *)sectionsWithForm:(id<FXForm>)form controller:(FXFormController *)formController;

@property (nonatomic, strong) id<FXForm> form;
@property (nonatomic, strong) id header;
@property (nonatomic, strong) id footer;
@property (nonatomic, strong) NSMutableArray *fields;
@property (nonatomic, assign) BOOL isSortable;

- (void)addNewField;
- (void)removeFieldAtIndex:(NSUInteger)index;
- (void)moveFieldAtIndex:(NSUInteger)index1 toIndex:(NSUInteger)index2;

@end
