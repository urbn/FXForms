//
//  FXFormTableCells.m
//  BasicExample
//
//  Created by Joseph Ridenour on 2/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormTableCells.h"
#import "FXFormsDefines.h"
#import "FXFormField.h"
#import "FXFormController.h"
#import "FXTableFormController.h"

#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma clang diagnostic ignored "-Wreceiver-is-weak"
#pragma clang diagnostic ignored "-Wconversion"
#pragma clang diagnostic ignored "-Wgnu"


@implementation FXFormBaseCell
@synthesize field = _field;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        self.textLabel.font = [UIFont boldSystemFontOfSize:17];
        FXFormLabelSetMinFontSize(self.textLabel, FXFormFieldMinFontSize);
        self.detailTextLabel.font = [UIFont systemFontOfSize:17];
        FXFormLabelSetMinFontSize(self.detailTextLabel, FXFormFieldMinFontSize);
        
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)
        {
            self.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else
        {
            self.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setUp];
    }
    return self;
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    if (![keyPath isEqualToString:@"style"])
    {
        [super setValue:value forKeyPath:keyPath];
    }
}

- (void)setField:(FXFormField *)field
{
    _field = field;
    [self update];
    [self setNeedsLayout];
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType
{
    //don't distinguish between these, because we're always in edit mode
    super.accessoryType = accessoryType;
    super.editingAccessoryType = accessoryType;
}

- (void)setEditingAccessoryType:(UITableViewCellAccessoryType)editingAccessoryType
{
    //don't distinguish between these, because we're always in edit mode
    [self setAccessoryType:editingAccessoryType];
}

- (void)setAccessoryView:(UIView *)accessoryView
{
    //don't distinguish between these, because we're always in edit mode
    super.accessoryView = accessoryView;
    super.editingAccessoryView = accessoryView;
}

- (void)setEditingAccessoryView:(UIView *)editingAccessoryView
{
    //don't distinguish between these, because we're always in edit mode
    [self setAccessoryView:editingAccessoryView];
}

- (UITableView *)tableView
{
    UITableView *view = (UITableView *)[self superview];
    while (![view isKindOfClass:[UITableView class]])
    {
        view = (UITableView *)[view superview];
    }
    return view;
}

- (NSIndexPath *)indexPathForNextCell
{
    UITableView *tableView = [self tableView];
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    if (indexPath)
    {
        //get next indexpath
        if ([tableView numberOfRowsInSection:indexPath.section] > indexPath.row + 1)
        {
            return [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        }
        else if ([tableView numberOfSections] > indexPath.section + 1)
        {
            return [NSIndexPath indexPathForRow:0 inSection:indexPath.section + 1];
        }
    }
    return nil;
}

- (UITableViewCell <FXFormFieldCell> *)nextCell
{
    UITableView *tableView = [self tableView];
    NSIndexPath *indexPath = [self indexPathForNextCell];
    if (indexPath)
    {
        //get next cell
        return (UITableViewCell <FXFormFieldCell> *)[tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (void)setUp
{
    //override
}

- (void)update
{
    //override
}

- (void)didSelectWithTableView:(__unused UITableView *)tableView controller:(__unused UIViewController *)controller
{
    //override
}

@end


@implementation FXFormDefaultCell

- (void)update
{
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription];
    
    if ([self.field.type isEqualToString:FXFormFieldTypeLabel])
    {
        self.accessoryType = UITableViewCellAccessoryNone;
        if (!self.field.action)
        {
            self.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    else if ([self.field isSubform] || self.field.segue)
    {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeBoolean] || [self.field.type isEqualToString:FXFormFieldTypeOption])
    {
        self.detailTextLabel.text = nil;
        self.accessoryType = [self.field.value boolValue]? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
    }
    else if (self.field.action)
    {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    else
    {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

- (void)didSelectWithTableView:(UITableView *)tableView controller:(UIViewController *)controller
{
    if ([self.field.type isEqualToString:FXFormFieldTypeBoolean] || [self.field.type isEqualToString:FXFormFieldTypeOption])
    {
        [FXFormsFirstResponder(tableView) resignFirstResponder];
        self.field.value = @(![self.field.value boolValue]);
        if (self.field.action) self.field.action(self);
        self.accessoryType = [self.field.value boolValue]? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
        if ([self.field.type isEqualToString:FXFormFieldTypeOption])
        {
            NSIndexPath *indexPath = [tableView indexPathForCell:self];
            if (indexPath)
            {
                //reload section, in case fields are linked
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
        else
        {
            //deselect the cell
            [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
        }
    }
    else if (self.field.action && (![self.field isSubform] || !self.field.options))
    {
        //action takes precendence over segue or subform - you can implement these yourself in the action
        //the exception is for options fields, where the action will be called when the option is tapped
        //TODO: do we need to make other exceptions? Or is there a better way to handle actions for subforms?
        [FXFormsFirstResponder(tableView) resignFirstResponder];
        self.field.action(self);
        [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
    }
    else if (self.field.segue && [self.field.segue class] != self.field.segue)
    {
        //segue takes precendence over subform - you have to handle setup of subform yourself
        [FXFormsFirstResponder(tableView) resignFirstResponder];
        if ([self.field.segue isKindOfClass:[UIStoryboardSegue class]])
        {
            [controller prepareForSegue:self.field.segue sender:self];
            [(UIStoryboardSegue *)self.field.segue perform];
        }
        else if ([self.field.segue isKindOfClass:[NSString class]])
        {
            [controller performSegueWithIdentifier:self.field.segue sender:self];
        }
    }
    else if ([self.field isSubform])
    {
        [FXFormsFirstResponder(tableView) resignFirstResponder];
        UIViewController *subcontroller = nil;
        if ([self.field.valueClass isSubclassOfClass:[UIViewController class]])
        {
            subcontroller = self.field.value ?: [[self.field.valueClass alloc] init];
        }
        else if (self.field.viewController && self.field.viewController == [self.field.viewController class])
        {
            subcontroller = [[self.field.viewController alloc] init];
            ((id <FXFormFieldViewController>)subcontroller).field = self.field;
        }
        else if ([self.field.viewController isKindOfClass:[UIViewController class]])
        {
            subcontroller = self.field.viewController;
            ((id <FXFormFieldViewController>)subcontroller).field = self.field;
        }
        else
        {
            subcontroller = [[self.field.viewController ?: [FXFormTableViewController class] alloc] init];
            ((id <FXFormFieldViewController>)subcontroller).field = self.field;
        }
        if (!subcontroller.title) subcontroller.title = self.field.title;
        if (self.field.segue)
        {
            UIStoryboardSegue *segue = [[self.field.segue alloc] initWithIdentifier:self.field.key source:controller destination:subcontroller];
            [controller prepareForSegue:self.field.segue sender:self];
            [segue perform];
        }
        else
        {
            NSAssert(controller.navigationController != nil, @"Attempted to push a sub-viewController from a form that is not embedded inside a UINavigationController. That won't work!");
            [controller.navigationController pushViewController:subcontroller animated:YES];
        }
    }
}

@end


@interface FXFormTextFieldCell () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, assign, getter = isReturnKeyOverriden) BOOL returnKeyOverridden;

@end


@implementation FXFormTextFieldCell

- (void)setUp
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 21)];
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin |UIViewAutoresizingFlexibleLeftMargin;
    self.textField.font = [UIFont systemFontOfSize:self.textLabel.font.pointSize];
    self.textField.minimumFontSize = FXFormLabelMinFontSize(self.textLabel);
    self.textField.textColor = [UIColor colorWithRed:0.275f green:0.376f blue:0.522f alpha:1.000f];
    self.textField.delegate = self;
    [self.contentView addSubview:self.textField];
    
    [self.contentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.textField action:NSSelectorFromString(@"becomeFirstResponder")]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:UITextFieldTextDidChangeNotification object:self.textField];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _textField.delegate = nil;
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
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
    if (block)
    {
        if ([keyPath isEqualToString:@"textField.returnKeyType"])
        {
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect labelFrame = self.textLabel.frame;
    labelFrame.size.width = MIN(MAX([self.textLabel sizeThatFits:CGSizeZero].width, FXFormFieldMinLabelWidth), FXFormFieldMaxLabelWidth);
    self.textLabel.frame = labelFrame;
    
    CGRect textFieldFrame = self.textField.frame;
    textFieldFrame.origin.x = self.textLabel.frame.origin.x + MAX(FXFormFieldMinLabelWidth, self.textLabel.frame.size.width) + FXFormFieldLabelSpacing;
    textFieldFrame.origin.y = (self.contentView.bounds.size.height - textFieldFrame.size.height) / 2;
    textFieldFrame.size.width = self.textField.superview.frame.size.width - textFieldFrame.origin.x - FXFormFieldPaddingRight;
    if (![self.textLabel.text length])
    {
        textFieldFrame.origin.x = FXFormFieldPaddingLeft;
        textFieldFrame.size.width = self.contentView.bounds.size.width - FXFormFieldPaddingLeft - FXFormFieldPaddingRight;
    }
    else if (self.textField.textAlignment == NSTextAlignmentRight)
    {
        textFieldFrame.origin.x = self.textLabel.frame.origin.x + labelFrame.size.width + FXFormFieldLabelSpacing;
        textFieldFrame.size.width = self.textField.superview.frame.size.width - textFieldFrame.origin.x - FXFormFieldPaddingRight;
    }
    self.textField.frame = textFieldFrame;
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.textField.placeholder = [self.field.placeholder fieldDescription];
    self.textField.text = [self.field fieldDescription];
    
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.textAlignment = [self.field.title length]? NSTextAlignmentRight: NSTextAlignmentLeft;
    self.textField.secureTextEntry = NO;
    
    if ([self.field.type isEqualToString:FXFormFieldTypeText])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeDefault;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        self.textField.keyboardType = UIKeyboardTypeDefault;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeUnsigned])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeNumberPad;
        self.textField.textAlignment = NSTextAlignmentRight;
    }
    else if ([@[FXFormFieldTypeNumber, FXFormFieldTypeInteger, FXFormFieldTypeFloat] containsObject:self.field.type])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        self.textField.textAlignment = NSTextAlignmentRight;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypePassword])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeDefault;
        self.textField.secureTextEntry = YES;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeEmail])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeEmailAddress;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypePhone])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypePhonePad;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeURL])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeURL;
    }
}

- (BOOL)textFieldShouldBeginEditing:(__unused UITextField *)textField
{
    //welcome to hacksville, population: you
    if (!self.returnKeyOverridden)
    {
        //get return key type
        UIReturnKeyType returnKeyType = UIReturnKeyDone;
        UITableViewCell <FXFormFieldCell> *nextCell = [self nextCell];
        if ([nextCell canBecomeFirstResponder])
        {
            returnKeyType = UIReturnKeyNext;
        }
        
        self.textField.returnKeyType = returnKeyType;
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(__unused UITextField *)textField
{
    [self.textField selectAll:nil];
}

- (void)textDidChange
{
    [self updateFieldValue];
}

- (BOOL)textFieldShouldReturn:(__unused UITextField *)textField
{
    if (self.textField.returnKeyType == UIReturnKeyNext)
    {
        [[self nextCell] becomeFirstResponder];
    }
    else
    {
        [self.textField resignFirstResponder];
    }
    return NO;
}

- (void)textFieldDidEndEditing:(__unused UITextField *)textField
{
    [self updateFieldValue];
    
    if (self.field.action) self.field.action(self);
}

- (void)updateFieldValue
{
    self.field.value = self.textField.text;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    return [self.textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    return [self.textField resignFirstResponder];
}

@end


@interface FXFormTextViewCell () <UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;

@end


@implementation FXFormTextViewCell

+ (CGFloat)heightForField:(FXFormField *)field width:(CGFloat)width
{
    static UITextView *textView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        textView = [[UITextView alloc] init];
        textView.font = [UIFont systemFontOfSize:17];
    });
    
    textView.text = [field fieldDescription] ?: @" ";
    CGSize textViewSize = [textView sizeThatFits:CGSizeMake(width - FXFormFieldPaddingLeft - FXFormFieldPaddingRight, FLT_MAX)];
    
    CGFloat height = [field.title length]? 21: 0; // label height
    height += FXFormFieldPaddingTop + ceilf(textViewSize.height) + FXFormFieldPaddingBottom;
    return height;
}

- (void)setUp
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 21)];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    self.textView.font = [UIFont systemFontOfSize:17];
    self.textView.textColor = [UIColor colorWithRed:0.275f green:0.376f blue:0.522f alpha:1.000f];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.delegate = self;
    self.textView.scrollEnabled = NO;
    [self.contentView addSubview:self.textView];
    
    self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    self.detailTextLabel.numberOfLines = 0;
    
    [self.contentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.textView action:NSSelectorFromString(@"becomeFirstResponder")]];
}

- (void)dealloc
{
    _textView.delegate = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect labelFrame = self.textLabel.frame;
    labelFrame.origin.y = FXFormFieldPaddingTop;
    labelFrame.size.width = MIN(MAX([self.textLabel sizeThatFits:CGSizeZero].width, FXFormFieldMinLabelWidth), FXFormFieldMaxLabelWidth);
    self.textLabel.frame = labelFrame;
    
    CGRect textViewFrame = self.textView.frame;
    textViewFrame.origin.x = FXFormFieldPaddingLeft;
    textViewFrame.origin.y = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;
    textViewFrame.size.width = self.contentView.bounds.size.width - FXFormFieldPaddingLeft - FXFormFieldPaddingRight;
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)];
    textViewFrame.size.height = ceilf(textViewSize.height);
    if (![self.textLabel.text length])
    {
        textViewFrame.origin.y = self.textLabel.frame.origin.y;
    }
    self.textView.frame = textViewFrame;
    
    textViewFrame.origin.x += 5;
    textViewFrame.size.width -= 5;
    self.detailTextLabel.frame = textViewFrame;
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.size.height = self.textView.frame.origin.y + self.textView.frame.size.height + FXFormFieldPaddingBottom;
    self.contentView.frame = contentViewFrame;
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.textView.text = [self.field fieldDescription];
    self.detailTextLabel.text = self.field.placeholder;
    self.detailTextLabel.hidden = ([self.textView.text length] > 0);
    
    self.textView.returnKeyType = UIReturnKeyDefault;
    self.textView.textAlignment = NSTextAlignmentLeft;
    self.textView.secureTextEntry = NO;
    
    if ([self.field.type isEqualToString:FXFormFieldTypeText])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeDefault;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        self.textView.keyboardType = UIKeyboardTypeDefault;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeUnsigned])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeNumberPad;
    }
    else if ([@[FXFormFieldTypeNumber, FXFormFieldTypeInteger, FXFormFieldTypeFloat] containsObject:self.field.type])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypePassword])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeDefault;
        self.textView.secureTextEntry = YES;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeEmail])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeEmailAddress;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypePhone])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypePhonePad;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeURL])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeURL;
    }
}

- (void)textViewDidBeginEditing:(__unused UITextView *)textView
{
    [self.textView selectAll:nil];
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self updateFieldValue];
    
    //show/hide placeholder
    self.detailTextLabel.hidden = ([textView.text length] > 0);
    
    //resize the tableview if required
    UITableView *tableView = [self tableView];
    [tableView beginUpdates];
    [tableView endUpdates];
    
    //scroll to show cursor
    CGRect cursorRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.end];
    [tableView scrollRectToVisible:[tableView convertRect:cursorRect fromView:self.textView] animated:YES];
}

- (void)textViewDidEndEditing:(__unused UITextView *)textView
{
    [self updateFieldValue];
    
    if (self.field.action) self.field.action(self);
}

- (void)updateFieldValue
{
    self.field.value = self.textView.text;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    return [self.textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    return [self.textView resignFirstResponder];
}

@end


@implementation FXFormSwitchCell

- (void)setUp
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryView = [[UISwitch alloc] init];
    [self.switchControl addTarget:self action:@selector(valueChanged) forControlEvents:UIControlEventValueChanged];
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.switchControl.on = [self.field.value boolValue];
}

- (UISwitch *)switchControl
{
    return (UISwitch *)self.accessoryView;
}

- (void)valueChanged
{
    self.field.value = @(self.switchControl.on);
    
    if (self.field.action) self.field.action(self);
}

@end


@implementation FXFormStepperCell

- (void)setUp
{
    UIStepper *stepper = [[UIStepper alloc] init];
    stepper.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    UIView *wrapper = [[UIView alloc] initWithFrame:stepper.frame];
    [wrapper addSubview:stepper];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)
    {
        wrapper.frame = CGRectMake(0, 0, wrapper.frame.size.width + FXFormFieldPaddingRight, wrapper.frame.size.height);
    }
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryView = wrapper;
    [self.stepper addTarget:self action:@selector(valueChanged) forControlEvents:UIControlEventValueChanged];
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription];
    self.stepper.value = [self.field.value doubleValue];
}

- (UIStepper *)stepper
{
    return (UIStepper *)[self.accessoryView.subviews firstObject];
}

- (void)valueChanged
{
    self.field.value = @(self.stepper.value);
    self.detailTextLabel.text = [self.field fieldDescription];
    [self setNeedsLayout];
    
    if (self.field.action) self.field.action(self);
}

@end


@interface FXFormSliderCell ()

@property (nonatomic, strong) UISlider *slider;

@end


@implementation FXFormSliderCell

- (void)setUp
{
    self.slider = [[UISlider alloc] init];
    [self.slider addTarget:self action:@selector(valueChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.slider];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect sliderFrame = self.slider.frame;
    sliderFrame.origin.x = self.textLabel.frame.origin.x + self.textLabel.frame.size.width + FXFormFieldPaddingLeft;
    sliderFrame.origin.y = (self.contentView.frame.size.height - sliderFrame.size.height) / 2;
    sliderFrame.size.width = self.contentView.bounds.size.width - sliderFrame.origin.x - FXFormFieldPaddingRight;
    self.slider.frame = sliderFrame;
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.slider.value = [self.field.value doubleValue];
}

- (void)valueChanged
{
    self.field.value = @(self.slider.value);
    
    if (self.field.action) self.field.action(self);
}

@end


@interface FXFormDatePickerCell ()

@property (nonatomic, strong) UIDatePicker *datePicker;

@end


@implementation FXFormDatePickerCell

- (void)setUp
{
    self.datePicker = [[UIDatePicker alloc] init];
    [self.datePicker addTarget:self action:@selector(valueChanged) forControlEvents:UIControlEventValueChanged];
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription] ?: [self.field.placeholder fieldDescription];
    
    if ([self.field.type isEqualToString:FXFormFieldTypeDate])
    {
        self.datePicker.datePickerMode = UIDatePickerModeDate;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeTime])
    {
        self.datePicker.datePickerMode = UIDatePickerModeTime;
    }
    else
    {
        self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    }
    
    self.datePicker.date = self.field.value ?: ([self.field.placeholder isKindOfClass:[NSDate class]]? self.field.placeholder: [NSDate date]);
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (UIView *)inputView
{
    return self.datePicker;
}

- (void)valueChanged
{
    self.field.value = self.datePicker.date;
    self.detailTextLabel.text = [self.field fieldDescription];
    [self setNeedsLayout];
    
    if (self.field.action) self.field.action(self);
}

- (void)didSelectWithTableView:(UITableView *)tableView controller:(__unused UIViewController *)controller
{
    if (![self isFirstResponder])
    {
        [self becomeFirstResponder];
    }
    else
    {
        [self resignFirstResponder];
    }
    [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
}

@end


@interface FXFormImagePickerCell () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, weak) UIViewController *controller;

@end


@implementation FXFormImagePickerCell

- (void)setUp
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    self.accessoryView = imageView;
    [self setNeedsLayout];
}

- (void)dealloc
{
    _imagePickerController.delegate = nil;
}

- (void)layoutSubviews
{
    CGRect frame = self.imagePickerView.bounds;
    frame.size.height = self.bounds.size.height - 10;
    UIImage *image = self.imagePickerView.image;
    frame.size.width = image.size.height? image.size.width * (frame.size.height / image.size.height): 0;
    self.imagePickerView.bounds = frame;
    
    [super layoutSubviews];
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.imagePickerView.image = [self imageValue];
    [self setNeedsLayout];
}

- (UIImage *)imageValue
{
    if (self.field.value)
    {
        return self.field.value;
    }
    else if (self.field.placeholder)
    {
        UIImage *placeholderImage = self.field.placeholder;
        if ([placeholderImage isKindOfClass:[NSString class]])
        {
            placeholderImage = [UIImage imageNamed:self.field.placeholder];
        }
        return placeholderImage;
    }
    return nil;
}

- (UIImagePickerController *)imagePickerController
{
    if (!_imagePickerController)
    {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
        _imagePickerController.allowsEditing = YES;
    }
    return _imagePickerController;
}

- (UIImageView *)imagePickerView
{
    return (UIImageView *)self.accessoryView;
}

- (void)didSelectWithTableView:(UITableView *)tableView controller:(UIViewController *)controller
{
    [FXFormsFirstResponder(tableView) resignFirstResponder];
    [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
    
    if (!TARGET_IPHONE_SIMULATOR && ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [controller presentViewController:self.imagePickerController animated:YES completion:nil];
    }
    else if ([UIAlertController class])
    {
        UIAlertControllerStyle style = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)? UIAlertControllerStyleAlert: UIAlertControllerStyleActionSheet;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:style];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Take Photo", nil) style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self actionSheet:nil didDismissWithButtonIndex:0];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Photo Library", nil) style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self actionSheet:nil didDismissWithButtonIndex:1];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:NULL]];
        
        self.controller = controller;
        [controller presentViewController:alert animated:YES completion:NULL];
    }
    else
    {
        self.controller = controller;
        [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Take Photo", nil), NSLocalizedString(@"Photo Library", nil), nil] showInView:controller.view];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.field.value = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    if (self.field.action) self.field.action(self);
    [self update];
}

- (void)actionSheet:(__unused UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    switch (buttonIndex)
    {
        case 0:
        {
            sourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        }
        case 1:
        {
            sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        }
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:sourceType])
    {
        self.imagePickerController.sourceType = sourceType;
        [self.controller presentViewController:self.imagePickerController animated:YES completion:nil];
    }
    
    self.controller = nil;
}

@end


@interface FXFormOptionPickerCell () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) UIPickerView *pickerView;

@end


@implementation FXFormOptionPickerCell

- (void)setUp
{
    self.pickerView = [[UIPickerView alloc] init];
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
}

- (void)dealloc
{
    _pickerView.dataSource = nil;
    _pickerView.delegate = nil;
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription];
    
    NSUInteger index = self.field.value? [self.field.options indexOfObject:self.field.value]: NSNotFound;
    if (self.field.placeholder)
    {
        index = (index == NSNotFound)? 0: index + 1;
    }
    if (index != NSNotFound)
    {
        [self.pickerView selectRow:index inComponent:0 animated:NO];
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (UIView *)inputView
{
    return self.pickerView;
}

- (void)didSelectWithTableView:(UITableView *)tableView controller:(__unused UIViewController *)controller
{
    if (![self isFirstResponder])
    {
        [self becomeFirstResponder];
    }
    else
    {
        [self resignFirstResponder];
    }
    [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
}

- (NSInteger)numberOfComponentsInPickerView:(__unused UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(__unused UIPickerView *)pickerView numberOfRowsInComponent:(__unused NSInteger)component
{
    return [self.field optionCount];
}

- (NSString *)pickerView:(__unused UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(__unused NSInteger)component
{
    return [self.field optionDescriptionAtIndex:row];
}

- (void)pickerView:(__unused UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(__unused NSInteger)component
{
    [self.field setOptionSelected:YES atIndex:row];
    self.detailTextLabel.text = [self.field fieldDescription] ?: [self.field.placeholder fieldDescription];
    
    [self setNeedsLayout];
    
    if (self.field.action) self.field.action(self);
}

@end


@interface FXFormOptionSegmentsCell ()

@property (nonatomic, strong, readwrite) UISegmentedControl *segmentedControl;

@end


@implementation FXFormOptionSegmentsCell

- (void)setUp
{
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
    [self.segmentedControl addTarget:self action:@selector(valueChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.segmentedControl];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect segmentedControlFrame = self.segmentedControl.frame;
    segmentedControlFrame.origin.x = self.textLabel.frame.origin.x + self.textLabel.frame.size.width + FXFormFieldPaddingLeft;
    segmentedControlFrame.origin.y = (self.contentView.frame.size.height - segmentedControlFrame.size.height) / 2;
    segmentedControlFrame.size.width = self.contentView.bounds.size.width - segmentedControlFrame.origin.x - FXFormFieldPaddingRight;
    self.segmentedControl.frame = segmentedControlFrame;
}

- (void)update
{
    self.textLabel.text = self.field.title;
    
    [self.segmentedControl removeAllSegments];
    for (NSUInteger i = 0; i < [self.field optionCount]; i++)
    {
        [self.segmentedControl insertSegmentWithTitle:[self.field optionDescriptionAtIndex:i] atIndex:i animated:NO];
        if ([self.field isOptionSelectedAtIndex:i])
        {
            [self.segmentedControl setSelectedSegmentIndex:i];
        }
    }
}

- (void)valueChanged
{
    //note: this loop is to prevent bugs when field type is multiselect
    //which currently isn't supported by FXFormOptionSegmentsCell
    NSInteger selectedIndex = self.segmentedControl.selectedSegmentIndex;
    for (NSInteger i = 0; i < (NSInteger)[self.field optionCount]; i++)
    {
        [self.field setOptionSelected:(selectedIndex == i) atIndex:i];
    }
    
    if (self.field.action) self.field.action(self);
}

@end
