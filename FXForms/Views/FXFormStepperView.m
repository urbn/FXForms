//
//  FXFormStepperView.m
//  BasicExample
//
//  Created by Joseph Ridenour on 3/3/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormStepperView.h"
#import "FXFormController.h"
#import "FXFormsDefines.h"
#import "FXFormField.h"

@implementation FXFormStepperView

- (void)setup {
    [super setup];
    self.viewStyle = FXFormViewStyleValue1;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = FXFormViewAccessoryNone;
    
    UIStepper *stepper = [[UIStepper alloc] init];
    stepper.translatesAutoresizingMaskIntoConstraints = NO;
    [stepper addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [self setAccessoryView:stepper];
}

- (void)update {
    [super update];
    
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription];
    self.stepper.value = [self.field.value doubleValue];
}

- (UIStepper *)stepper {
    return (UIStepper *)self.accessoryView;
}

- (void)valueChanged:(UIStepper *)s {
    self.field.value = @(s.value);
    self.detailTextLabel.text = [self.field fieldDescription];
    
    if (self.field.action) self.field.action(self);
}

@end