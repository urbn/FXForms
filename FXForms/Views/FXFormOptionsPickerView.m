//
//  FXFormOptionsPickerView.m
//  BasicExample
//
//  Created by Joseph Ridenour on 3/3/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormOptionsPickerView.h"
#import "FXFormController.h"
#import "FXFormsDefines.h"
#import "FXFormField.h"
#import "FXFormController_Private.h"

@interface FXFormOptionPickerView () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, strong) UIPickerView *pickerView;
@end

@implementation FXFormOptionPickerView

#pragma mark - Flow
- (void)setup {
    [super setup];
    
    self.pickerView = [[UIPickerView alloc] init];
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
}

- (void)update {
    [super update];
    
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription];
    
    NSUInteger index = self.field.value? [self.field.options indexOfObject:self.field.value]: NSNotFound;
    if (self.field.placeholder) {
        index = (index == NSNotFound)? 0: index + 1;
    }
    if (index != NSNotFound) {
        [self.pickerView selectRow:(NSUInteger)index inComponent:0 animated:NO];
    }
}

- (void)didSelectWithView:(__unused UIView *)v withViewController:(__unused UIViewController *)vc withFormController:(FXFormController *)formController {
    if (![self isFirstResponder]) {
        [self becomeFirstResponder];
    }
    else {
        [self resignFirstResponder];
    }
    [formController deselectRowAtIndexPath:nil animated:YES];
    
    // Update the currentResponderCell on the formController
    NSIndexPath *indexPathForCell = [self.field.formController indexPathForField:self.field];
    id <FXFormFieldCell> currentCell = [self.field.formController cellForRowAtIndexPath:indexPathForCell];
    self.field.formController.currentResponderCell = currentCell;
}

#pragma mark - Responder chain
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (UIView *)inputView {
    return self.pickerView;
}

#pragma mark - Picker Logic
- (NSInteger)numberOfComponentsInPickerView:(__unused UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(__unused UIPickerView *)pickerView numberOfRowsInComponent:(__unused NSInteger)component {
    return (NSInteger)[self.field optionCount];
}

- (NSString *)pickerView:(__unused UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(__unused NSInteger)component {
    return [self.field optionDescriptionAtIndex:(NSUInteger)row];
}

- (void)pickerView:(__unused UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(__unused NSInteger)component {
    [self.field setOptionSelected:YES atIndex:(NSUInteger)row];
    self.detailTextLabel.text = [self.field fieldDescription] ?: [self.field.placeholder fieldDescription];
    
    if (self.field.action) self.field.action(self);
}

@end
