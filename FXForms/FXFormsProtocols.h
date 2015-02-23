//
//  FXFormsProtocols.h
//  BasicExample
//
//  Created by Joseph Ridenour on 2/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FXFormField;

@protocol FXForm <NSObject>
@optional

- (NSArray *)fields;
- (NSArray *)extraFields;
- (NSArray *)excludedFields;

// informal protocol:

// - (NSDictionary *)<fieldKey>Field
// - (NSString *)<fieldKey>FieldDescription

@end


@protocol FXFormControllerDelegate <NSObject>

@end


@protocol FXFormFieldViewController <NSObject>

@property (nonatomic, strong) FXFormField *field;

@end


@protocol FXFormFieldCell <NSObject>

@property (nonatomic, strong) FXFormField *field;

@optional

+ (CGFloat)heightForField:(FXFormField *)field width:(CGFloat)width;
- (void)didSelectWithTableView:(UITableView *)tableView
                    controller:(UIViewController *)controller;
@end
