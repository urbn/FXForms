//
//  FXFormSwitchView.m
//  BasicExample
//
//  Created by Joseph Ridenour on 3/3/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormSwitchView.h"
#import "FXFormField.h"

@implementation FXFormSwitchView

- (void)setup {
    [super setup];
    self.selectionStyle = FXFormViewSelectionStyleNone;
    self.accessoryType = FXFormViewAccessoryNone;
    
    UISwitch *s = [[UISwitch alloc] init];
    s.translatesAutoresizingMaskIntoConstraints = NO;
    [s addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [self setAccessoryView:s];
}

- (void)update {
    [super update];
    self.textLabel.text = self.field.title;
    self.switchControl.on = [self.field.value boolValue];
}

- (UISwitch *)switchControl {
    return (UISwitch *)self.accessoryView;
}

- (void)valueChanged:(UISwitch *)s {
    self.field.value = @(s.on);
    if (self.field.action) self.field.action(self);
}

@end
