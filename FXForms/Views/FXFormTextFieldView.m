//
//  FXFormTextFieldCell.m
//  BasicExample
//
//  Created by Joseph Ridenour on 3/3/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormTextFieldView.h"
#import "FXFormsDefines.h"
#import "FXFormField.h"
#import "FXFormController.h"
#import "FXFormController_Private.h"

@interface FXFormTextFieldView() <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, assign) BOOL returnKeyOverridden;
@end

@implementation FXFormTextFieldView

- (void)setup {
    _textAlignment = NSTextAlignmentRight;
    [super setup];
    self.viewStyle = FXFormViewStyleDefault;
    self.selectionStyle = FXFormViewSelectionStyleNone;
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 21)];
    self.textField.backgroundColor = [UIColor clearColor];
    self.textField.font = [UIFont systemFontOfSize:self.textLabel.font.pointSize];
    self.textField.minimumFontSize = FXFormLabelMinFontSize(self.textLabel);
    self.textField.textColor = [UIColor colorWithRed:0.275f green:0.376f blue:0.522f alpha:1.000f];
    self.textField.delegate = self;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.textField];
    
    [self.contentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.textField action:NSSelectorFromString(@"becomeFirstResponder")]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:UITextFieldTextDidChangeNotification object:self.textField];
}

- (void)updateConstraints {
    [super updateConstraints];
    
    if (!self.textField) {
        return;
    }
    
    UIView *l = self.textLabel;
    UITextField *tf = self.textField;
    NSDictionary *views = NSDictionaryOfVariableBindings(l, tf);
    [tf setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [l setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [l setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    // If we are not giving a title, then we do not want any space between the title and label
    NSDictionary *metrics = @{@"s": ([self.field.title length] ? @8 : @0)};
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[l]-s-[tf]-|" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[tf]-|" options:0 metrics:nil views:views]];
}

- (void)update {
    [super update];
    
    self.textLabel.text = self.field.title;
    self.textField.placeholder = [self.field.placeholder fieldDescription];
    self.textField.text = [self.field fieldDescription];
    
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.textAlignment = [self.field.title length] ? [self textAlignment] : NSTextAlignmentLeft;
    self.textField.secureTextEntry = NO;
    
    if ([self.field.type isEqualToString:FXFormFieldTypeText]) {
        self.textField.autocorrectionType = UITextAutocorrectionTypeDefault;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        self.textField.keyboardType = UIKeyboardTypeDefault;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeUnsigned]) {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeNumberPad;
        self.textField.textAlignment = NSTextAlignmentRight;
    }
    else if ([@[FXFormFieldTypeNumber, FXFormFieldTypeInteger, FXFormFieldTypeFloat] containsObject:self.field.type]) {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        self.textField.textAlignment = NSTextAlignmentRight;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypePassword]) {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeDefault;
        self.textField.secureTextEntry = YES;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeEmail]) {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeEmailAddress;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypePhone]) {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypePhonePad;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeURL]) {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeURL;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - KVC
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath {
    //TODO: is there a less hacky fix for this?
    static NSDictionary *specialCases = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        specialCases = @{@"textField.autocapitalizationType": ^(UITextField *f, NSInteger v){ f.autocapitalizationType = v; },
                         @"textField.autocorrectionType": ^(UITextField *f, NSInteger v){ f.autocorrectionType = v; },
                         @"textField.spellCheckingType": ^(UITextField *f, NSInteger v){ f.spellCheckingType = v; },
                         @"textField.keyboardType": ^(UITextField *f, NSInteger v){ f.keyboardType = v; },
                         @"textField.keyboardAppearance": ^(UITextField *f, NSInteger v){ f.keyboardAppearance = v; },
                         @"textField.returnKeyType": ^(UITextField *f, NSInteger v){ f.returnKeyType = v; },
                         @"textField.enablesReturnKeyAutomatically": ^(UITextField *f, NSInteger v){ f.enablesReturnKeyAutomatically = !!v; },
                         @"textField.secureTextEntry": ^(UITextField *f, NSInteger v){ f.secureTextEntry = !!v; }};
    });
    
    void (^block)(UITextField *f, NSInteger v) = specialCases[keyPath];
    if (block) {
        if ([keyPath isEqualToString:@"textField.returnKeyType"]) {
            //oh god, the hack, it burns
            self.returnKeyOverridden = YES;
        }
        
        block(self.textField, [value integerValue]);
    }
    else
    {
        [super setValue:value forKeyPath:keyPath];
    }
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    if (_textAlignment == textAlignment) {
        return;
    }
    
    _textAlignment = textAlignment;
    [self update];
}

#pragma mark - TextField
- (BOOL)textFieldShouldBeginEditing:(__unused UITextField *)textField {
    //welcome to hacksville, population: you
    if (!self.returnKeyOverridden) {
        //get return key type
        UIReturnKeyType returnKeyType = UIReturnKeyDone;
        UIResponder <FXFormFieldCell> *nextCell = [self nextCell];
        if ([nextCell canBecomeFirstResponder])
        {
            returnKeyType = UIReturnKeyNext;
        }
        
        self.textField.returnKeyType = returnKeyType;
    }
    
    // Update the currentResponderCell on the formController
    NSIndexPath *indexPathForCell = [self.field.formController indexPathForField:self.field];
    id <FXFormFieldCell> currentCell = [self.field.formController cellForRowAtIndexPath:indexPathForCell];
    self.field.formController.currentResponderCell = currentCell;
    
    return YES;
}

- (void)textDidChange {
    [self updateFieldValue];
}

- (BOOL)textFieldShouldReturn:(__unused UITextField *)textField {
    if (self.textField.returnKeyType == UIReturnKeyNext) {
        [[self nextCell] becomeFirstResponder];
    }
    else {
        [self.textField resignFirstResponder];
    }
    return NO;
}

- (void)textFieldDidEndEditing:(__unused UITextField *)textField {
    [self updateFieldValue];
    
    if (self.field.action) self.field.action(self);
}

- (void)updateFieldValue {
    self.field.value = self.textField.text;
}

#pragma mark - First Responder
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [self.textField resignFirstResponder];
}

@end

