//
//  FXFormField.h
//  BasicExample
//
//  Created by Joseph Ridenour on 2/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXFormsProtocols.h"

@class FXFormController;

@interface FXFormField : NSObject

+ (NSArray *)fieldsWithForm:(id<FXForm>)form controller:(FXFormController *)formController;

@property (nonatomic, readonly) id<FXForm> form;
@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) id placeholder;
@property (nonatomic, readonly) NSArray *options;
@property (nonatomic, readonly) NSDictionary *fieldTemplate;
@property (nonatomic, readonly) BOOL isSortable;
@property (nonatomic, readonly) BOOL isInline;
@property (nonatomic, readonly) Class valueClass;
@property (nonatomic, readonly) Class cellClass;
@property (nonatomic, readonly) id viewController;
@property (nonatomic, readonly) void (^action)(id sender);
@property (nonatomic, readonly) id segue;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) id header;
@property (nonatomic, strong) id footer;
@property (nonatomic, weak) FXFormController *formController;
@property (nonatomic, readonly) NSMutableDictionary *cellConfig;

- (BOOL)isSubform;
- (BOOL)isOrderedCollectionType;
- (BOOL)isCollectionType;

- (NSUInteger)optionCount;
- (id)optionAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfOption:(id)option;
- (NSString *)optionDescriptionAtIndex:(NSUInteger)index;
- (void)setOptionSelected:(BOOL)selected atIndex:(NSUInteger)index;
- (BOOL)isOptionSelectedAtIndex:(NSUInteger)index;

@end
