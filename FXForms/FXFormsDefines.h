//
//  FXFormsDefines.h
//  BasicExample
//
//  Created by Joseph Ridenour on 2/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXFormsProtocols.h"

UIKIT_EXTERN NSString *const FXFormFieldKey; //key
UIKIT_EXTERN NSString *const FXFormFieldType; //type
UIKIT_EXTERN NSString *const FXFormFieldClass; //class
UIKIT_EXTERN NSString *const FXFormFieldCell; //cell
UIKIT_EXTERN NSString *const FXFormFieldTitle; //title
UIKIT_EXTERN NSString *const FXFormFieldPlaceholder; //placeholder
UIKIT_EXTERN NSString *const FXFormFieldDefaultValue; //default
UIKIT_EXTERN NSString *const FXFormFieldOptions; //options
UIKIT_EXTERN NSString *const FXFormFieldTemplate; //template
UIKIT_EXTERN NSString *const FXFormFieldValueTransformer; //valueTransformer
UIKIT_EXTERN NSString *const FXFormFieldAction; //action
UIKIT_EXTERN NSString *const FXFormFieldSegue; //segue
UIKIT_EXTERN NSString *const FXFormFieldHeader; //header
UIKIT_EXTERN NSString *const FXFormFieldFooter; //footer
UIKIT_EXTERN NSString *const FXFormFieldInline; //inline
UIKIT_EXTERN NSString *const FXFormFieldSortable; //sortable
UIKIT_EXTERN NSString *const FXFormFieldViewController; //viewController

UIKIT_EXTERN NSString *const FXFormFieldTypeDefault; //default
UIKIT_EXTERN NSString *const FXFormFieldTypeLabel; //label
UIKIT_EXTERN NSString *const FXFormFieldTypeText; //text
UIKIT_EXTERN NSString *const FXFormFieldTypeLongText; //longtext
UIKIT_EXTERN NSString *const FXFormFieldTypeURL; //url
UIKIT_EXTERN NSString *const FXFormFieldTypeEmail; //email
UIKIT_EXTERN NSString *const FXFormFieldTypePhone; //phone
UIKIT_EXTERN NSString *const FXFormFieldTypePassword; //password
UIKIT_EXTERN NSString *const FXFormFieldTypeNumber; //number
UIKIT_EXTERN NSString *const FXFormFieldTypeInteger; //integer
UIKIT_EXTERN NSString *const FXFormFieldTypeUnsigned; //unsigned
UIKIT_EXTERN NSString *const FXFormFieldTypeFloat; //float
UIKIT_EXTERN NSString *const FXFormFieldTypeBitfield; //bitfield
UIKIT_EXTERN NSString *const FXFormFieldTypeBoolean; //boolean
UIKIT_EXTERN NSString *const FXFormFieldTypeOption; //option
UIKIT_EXTERN NSString *const FXFormFieldTypeDate; //date
UIKIT_EXTERN NSString *const FXFormFieldTypeTime; //time
UIKIT_EXTERN NSString *const FXFormFieldTypeDateTime; //datetime
UIKIT_EXTERN NSString *const FXFormFieldTypeImage; //image

UIKIT_EXTERN NSString *const FXFormsException;

UIKIT_EXTERN const CGFloat FXFormFieldLabelSpacing;
UIKIT_EXTERN const CGFloat FXFormFieldMinLabelWidth;
UIKIT_EXTERN const CGFloat FXFormFieldMaxLabelWidth;
UIKIT_EXTERN const CGFloat FXFormFieldMinFontSize;
UIKIT_EXTERN const CGFloat FXFormFieldPaddingLeft;
UIKIT_EXTERN const CGFloat FXFormFieldPaddingRight;
UIKIT_EXTERN const CGFloat FXFormFieldPaddingTop;
UIKIT_EXTERN const CGFloat FXFormFieldPaddingBottom;



Class FXFormClassFromString(NSString *className);
UIView *FXFormsFirstResponder(UIView *view);

#pragma mark -
#pragma mark Models

CGFloat FXFormLabelMinFontSize(UILabel *label);
void FXFormLabelSetMinFontSize(UILabel *label, CGFloat fontSize);
NSArray *FXFormProperties(id<FXForm> form);
BOOL FXFormOverridesSelector(id<FXForm> form, SEL selector);
BOOL FXFormCanGetValueForKey(id<FXForm> form, NSString *key);
BOOL FXFormCanSetValueForKey(id<FXForm> form, NSString *key);
NSString *FXFormFieldInferType(NSDictionary *dictionary);
Class FXFormFieldInferClass(NSDictionary *dictionary);
void FXFormPreprocessFieldDictionary(NSMutableDictionary *dictionary);



@interface NSObject (FXForms)

- (NSString *)fieldDescription;

@end
