//
//  FXFormDefaultView.m
//  TemplateFieldsExample
//
//  Created by Joseph Ridenour on 3/3/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormDefaultView.h"
#import "FXFormsDefines.h"
#import "FXFormField.h"
#import "FXFormController.h"
#import "FXFormController_Private.h"

@implementation FXFormDefaultView

- (void)update {
    [super update];
    
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription];
    
    if ([self.field.type isEqualToString:FXFormFieldTypeLabel])
    {
        self.accessoryType = FXFormViewAccessoryNone;
        if (!self.field.action)
        {
            self.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    else if ([self.field isSubform] || self.field.segue)
    {
        self.accessoryType = FXFormViewAccessoryDisclosureIndicator;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeBoolean] || [self.field.type isEqualToString:FXFormFieldTypeOption])
    {
        self.detailTextLabel.text = nil;
        self.accessoryType = [self.field.value boolValue]? FXFormViewAccessoryCheckmark: FXFormViewAccessoryNone;
    }
    else if (self.field.action)
    {
        self.accessoryType = FXFormViewAccessoryNone;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    else
    {
        self.accessoryType = FXFormViewAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

- (void)didSelectWithView:(UIView *)view withViewController:(UIViewController *)controller withFormController:(FXFormController *)formController {
    
    // Resign the view
    [FXFormsFirstResponder(view) resignFirstResponder];
    
    if ([self.field.type isEqualToString:FXFormFieldTypeBoolean] || [self.field.type isEqualToString:FXFormFieldTypeOption]) {
        self.field.value = @(![self.field.value boolValue]);    // Toggle the value
        if (self.field.action) self.field.action(self);         // If action attached, then call it.
        self.accessoryType = [self.field.value boolValue]? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
        if ([self.field.type isEqualToString:FXFormFieldTypeOption])
        {
            NSIndexPath *indexPath = [formController indexPathForField:self.field];
            if (indexPath) {
                //reload section, in case fields are linked
                [formController performUpdates:^{
                    [formController refreshRowsInSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
                } withCompletion:nil];
            }
        }
        else {
            //deselect the cell
            [formController deselectRowAtIndexPath:nil animated:YES];
        }
    }
    else if (self.field.action && (![self.field isSubform] || !self.field.options)) {
        //action takes precendence over segue or subform - you can implement these yourself in the action
        //the exception is for options fields, where the action will be called when the option is tapped
        //TODO: do we need to make other exceptions? Or is there a better way to handle actions for subforms?
        self.field.action(self);
        [formController deselectRowAtIndexPath:nil animated:YES];
    }
    else if (self.field.segue && [self.field.segue class] != self.field.segue) {
        //segue takes precendence over subform - you have to handle setup of subform yourself
        [FXFormsFirstResponder(view) resignFirstResponder];
        if ([self.field.segue isKindOfClass:[UIStoryboardSegue class]]) {
            [controller prepareForSegue:self.field.segue sender:self];
            [(UIStoryboardSegue *)self.field.segue perform];
        }
        else if ([self.field.segue isKindOfClass:[NSString class]]) {
            [controller performSegueWithIdentifier:self.field.segue sender:self];
        }
    }
    else if ([self.field isSubform]) {
        [FXFormsFirstResponder(view) resignFirstResponder];
        UIViewController *subcontroller = nil;
        if ([self.field.valueClass isSubclassOfClass:[UIViewController class]]) {
            subcontroller = self.field.value ?: [[self.field.valueClass alloc] init];
        }
        else if (self.field.viewController && self.field.viewController == [self.field.viewController class]) {
            subcontroller = [[self.field.viewController alloc] init];
            ((id <FXFormFieldViewController>)subcontroller).field = self.field;
        }
        else if ([self.field.viewController isKindOfClass:[UIViewController class]]) {
            subcontroller = self.field.viewController;
            ((id <FXFormFieldViewController>)subcontroller).field = self.field;
        }
        else {
            subcontroller = [[self.field.viewController ?: [formController viewControllerClassForField:self.field] alloc] init];
            ((id <FXFormFieldViewController>)subcontroller).field = self.field;
        }
        if (!subcontroller.title) subcontroller.title = self.field.title;
        if (self.field.segue) {
            UIStoryboardSegue *segue = [[self.field.segue alloc] initWithIdentifier:self.field.key source:controller destination:subcontroller];
            [controller prepareForSegue:self.field.segue sender:self];
            [segue perform];
        }
        else {
            NSAssert(controller.navigationController != nil, @"Attempted to push a sub-viewController from a form that is not embedded inside a UINavigationController. That won't work!");
            [controller.navigationController pushViewController:subcontroller animated:YES];
        }
    }
}

@end
