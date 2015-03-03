//
//  FXFormDatePickerView.m
//  BasicExample
//
//  Created by Joseph Ridenour on 3/3/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormDatePickerView.h"
#import "FXFormController.h"
#import "FXFormsDefines.h"
#import "FXFormField.h"

@interface FXFormDatePickerView ()
@property (nonatomic, strong) UIDatePicker *datePicker;
@end

@implementation FXFormDatePickerView

- (void)setup {
    [super setup];
    
    self.datePicker = [[UIDatePicker alloc] init];
    [self.datePicker addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)update {
    [super update];
    
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription] ?: [self.field.placeholder fieldDescription];
    
    if ([self.field.type isEqualToString:FXFormFieldTypeDate]) {
        self.datePicker.datePickerMode = UIDatePickerModeDate;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeTime]) {
        self.datePicker.datePickerMode = UIDatePickerModeTime;
    }
    else {
        self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    }
    
    self.datePicker.date = self.field.value ?: ([self.field.placeholder isKindOfClass:[NSDate class]]? self.field.placeholder: [NSDate date]);
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (UIView *)inputView {
    return self.datePicker;
}

- (void)valueChanged:(UIDatePicker *)dp {
    self.field.value = dp.date;
    self.detailTextLabel.text = [self.field fieldDescription];
    
    if (self.field.action) self.field.action(self);
}

- (void)didSelectWithView:(__unused UIView *)view withViewController:(__unused UIViewController *)controller withFormController:(FXFormController *)formController {
    if (![self isFirstResponder]) {
        [self becomeFirstResponder];
    } else {
        [self resignFirstResponder];
    }
    
    [formController deselectRowAtIndexPath:nil animated:YES];
}

@end
