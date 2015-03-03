//
//  FXFormTextViewView.m
//  BasicExample
//
//  Created by Joseph Ridenour on 3/3/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormTextViewView.h"
#import "FXFormController.h"
#import "FXFormController_Private.h"
#import "FXFormsDefines.h"
#import "FXFormField.h"

@interface FXFormTextViewView() <UITextViewDelegate>
@property (nonatomic, strong) UITextView *textView;
@end

@implementation FXFormTextViewView
- (void)setup {
    [super setup];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 21)];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.font = [UIFont systemFontOfSize:17];
    self.textView.textColor = [UIColor colorWithRed:0.275f green:0.376f blue:0.522f alpha:1.000f];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.delegate = self;
    self.textView.scrollEnabled = NO;
    [self.contentView addSubview:self.textView];
    
    self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    self.detailTextLabel.numberOfLines = 0;
    
    [self.contentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.textView action:NSSelectorFromString(@"becomeFirstResponder")]];
    [self setNeedsUpdateConstraints];
}

- (void)dealloc {
    _textView.delegate = nil;
}

- (FXFormViewStyle)viewStyle {
    return FXFormViewStyleSubtitle;
}

- (void)updateConstraints {
    [super updateConstraints];
    
    UILabel *l = self.textLabel;
    UITextView *tv = self.textView;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(l, tv);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[tv]-|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[l][tv]|" options:0 metrics:nil views:views]];
}

- (void)update {
    [super update];
    
    self.textLabel.text = self.field.title;
    self.textView.text = [self.field fieldDescription];
    self.detailTextLabel.text = self.field.placeholder;
    self.detailTextLabel.hidden = ([self.textView.text length] > 0);
    
    self.textView.returnKeyType = UIReturnKeyDefault;
    self.textView.textAlignment = NSTextAlignmentLeft;
    self.textView.secureTextEntry = NO;
    
    if ([self.field.type isEqualToString:FXFormFieldTypeText]) {
        self.textView.autocorrectionType = UITextAutocorrectionTypeDefault;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        self.textView.keyboardType = UIKeyboardTypeDefault;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeUnsigned]) {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeNumberPad;
    }
    else if ([@[FXFormFieldTypeNumber, FXFormFieldTypeInteger, FXFormFieldTypeFloat] containsObject:self.field.type]) {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypePassword]) {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeDefault;
        self.textView.secureTextEntry = YES;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeEmail]) {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeEmailAddress;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypePhone]) {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypePhonePad;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeURL]) {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeURL;
    }
}

- (void)textViewDidBeginEditing:(__unused UITextView *)textView {
    [self.textView selectAll:nil];
}

- (void)textViewDidChange:(UITextView *)textView {
    [self updateFieldValue];
    
    //show/hide placeholder
    self.detailTextLabel.hidden = ([textView.text length] > 0);
    
    //resize the tableview if required
    
    //scroll to show cursor
    [self.field.formController performUpdates:nil withCompletion:nil];
    CGRect cursorRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.end];
    
    UIScrollView *sv = self.field.formController.scrollView;
    [sv scrollRectToVisible:[sv convertRect:cursorRect fromView:self.textView] animated:YES];
}

- (void)textViewDidEndEditing:(__unused UITextView *)textView {
    [self updateFieldValue];
    if (self.field.action) self.field.action(self);
}

- (void)updateFieldValue {
    self.field.value = self.textView.text;
}

#pragma mark - Responder
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    return [self.textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [self.textView resignFirstResponder];
}

@end
