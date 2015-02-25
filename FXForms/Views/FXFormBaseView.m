//
//  FXFormBaseView.m
//  BasicExample
//
//  Created by Joseph Ridenour on 2/23/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormBaseView.h"
#import "FXFormsDefines.h"
#import "FXFormField.h"
#import "FXFormController.h"
#import "FXFormController_Private.h"

typedef NS_ENUM(NSInteger, FXFormViewAccessoryType) {
    FXFormViewAccessoryNone,
    FXFormViewAccessoryDisclosureIndicator,
    FXFormViewAccessoryDetailDisclosureIndicator,
    FXFormViewAccessoryCheckmark,
};

typedef NS_ENUM(NSInteger, FXFormViewStyle) {
    FXFormViewStyleDefault,
    FXFormViewStyleValue1,
    FXFormViewStyleValue2,
    FXFormViewStyleSubtitle
};

typedef NS_ENUM(NSInteger, FXFormViewSelectionStyle) {
    FXFormViewSelectionStyleNone,
    FXFormViewSelectionStyleBlue,
    FXFormViewSelectionStyleGray,
    FXFormViewSelectionStyleDefault
};

IB_DESIGNABLE @interface FXFormBaseView()
@property (nonatomic, strong, readwrite) UIView *contentView;
@property (nonatomic, strong, readwrite) UILabel *textLabel;
@property (nonatomic, strong, readwrite) UILabel *detailTextLabel;

@property (nonatomic, strong) UIView *selectedBackgroundView;

@property (nonatomic, strong) UIView *accessoryView;

@property (nonatomic, assign) FXFormViewAccessoryType accessoryType;
@property (nonatomic, assign) FXFormViewSelectionStyle selectionStyle;
@property (nonatomic, assign) FXFormViewStyle viewStyle;

// Funsies
@property (nonatomic, copy) IBInspectable NSString *textLabelText;
@property (nonatomic, copy) IBInspectable NSString *detailTextLabelText;
@property (nonatomic, assign) IBInspectable NSInteger accessory;
@property (nonatomic, assign) IBInspectable NSInteger style;
@end


@implementation FXFormBaseView
@synthesize accessoryView = _accessoryView;
@synthesize field = _field;

#pragma mark - Init
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame: frame])) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

#pragma mark - Setters
- (void)setField:(FXFormField *)field {
    _field = field;
    if (FXFormCanGetValueForKey(field.form, field.key)) {
        self.viewStyle = FXFormViewStyleValue1;
    }
    [self update];
    [self setNeedsUpdateConstraints];
}

- (void)setAccessoryType:(FXFormViewAccessoryType)accessoryType {
    if (_accessoryType == accessoryType) {
        return;
    }
    _accessoryType = accessoryType;
    [_accessoryView removeFromSuperview];
    _accessoryView = nil;
    [self setNeedsUpdateConstraints];
}

- (void)setAccessoryView:(UIView *)accessoryView {
    if ([_accessoryView isEqual:accessoryView]) return;
    
    if (_accessoryView) {
        [_accessoryView removeFromSuperview];
    }
    
    _accessoryView = accessoryView;
    [self addSubview:accessoryView];
    [self setNeedsUpdateConstraints];
}

- (void)setSelected:(BOOL)selected {
    if (_selected == selected) return;
    
    _selected = selected;
    self.textLabel.highlighted =
    self.detailTextLabel.highlighted = selected;
    self.selectedBackgroundView.alpha = selected ? 1.f : 0.f;
}

- (void)setHighlighted:(BOOL)highlighted {
    if (_highlighted == highlighted) return;
    
    _highlighted = highlighted;
    self.textLabel.highlighted =
    self.detailTextLabel.highlighted = highlighted;
    self.selectedBackgroundView.alpha = highlighted ? 1.f : 0.f;
}

- (void)setViewStyle:(FXFormViewStyle)viewStyle {
    if (_viewStyle == viewStyle) return;
    
    _viewStyle = viewStyle;
    [self setNeedsUpdateConstraints];
}

- (void)setSelectionStyle:(FXFormViewSelectionStyle)selectionStyle {
    if (_selectionStyle == selectionStyle) {
        return;
    }
    _selectionStyle = selectionStyle;

    UIColor *c = selectionStyle == FXFormViewSelectionStyleBlue ? [UIColor blueColor] : ((selectionStyle == FXFormViewSelectionStyleGray) ? [UIColor lightGrayColor] : nil);
    if (c) {
        self.selectedBackgroundView.backgroundColor = [c colorWithAlphaComponent:.5f];
    }
    self.selectedBackgroundView.hidden = selectionStyle == FXFormViewSelectionStyleNone;
}

#pragma mark - Getters
- (UIView *)accessoryView {
    if (!_accessoryView && self.accessoryType != FXFormViewAccessoryNone) {
        _accessoryView = [[UIImageView alloc] initWithImage:[self _imageForAccessoryType]];
        _accessoryView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_accessoryView];
    }
    return _accessoryView;
}

- (UIImage *)_imageForAccessoryType {
    CGRect rect = CGRectMake(0, 0, 30.f, 30.f);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    rect = CGRectInset(rect, 5.f, 5.f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextClearRect(context, rect);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 2.f);
    
    CGFloat minX = CGRectGetMinX(rect), maxX = CGRectGetMaxX(rect);
    CGFloat minY = CGRectGetMinY(rect), maxY = CGRectGetMaxY(rect);
    CGFloat midX = CGRectGetMidX(rect), midY = CGRectGetMidY(rect);

    if (self.accessoryType == FXFormViewAccessoryCheckmark) {
        CGContextMoveToPoint(context, midX / 2.f, maxY - 10.f);
        CGContextAddLineToPoint(context, midX, maxY);
        CGContextAddLineToPoint(context, maxX, minY);
        CGContextStrokePath(context);
    } else if (self.accessoryType == FXFormViewAccessoryDisclosureIndicator) {
        CGContextMoveToPoint(context, midX, minY);
        CGContextAddLineToPoint(context, maxX, midY);
        CGContextAddLineToPoint(context, midX, maxY);
        CGContextStrokePath(context);
    } else if (self.accessoryType == FXFormViewAccessoryDetailDisclosureIndicator) {
        CGContextAddEllipseInRect(context, rect);
        CGContextMoveToPoint(context, midX, midY - 5.f);
        CGContextAddLineToPoint(context, midX, midY + 5.f);
        CGContextStrokePath(context);
        CGContextMoveToPoint(context, midX - 5.f, midY);
        CGContextAddLineToPoint(context, midX + 5.f, midY);
        CGContextStrokePath(context);
    }
    
    UIImage *i = [UIGraphicsGetImageFromCurrentImageContext() imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIGraphicsEndImageContext();
    
    return i;
}

#pragma mark - Flow
- (void)setup {
    UIView *sv = [[UIView alloc] initWithFrame:self.bounds];
    sv.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    sv.alpha = 0.f;
    sv.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5f];
    [self addSubview:sv];
    
    UIView *cv = [UIView new];
    cv.translatesAutoresizingMaskIntoConstraints = NO;
    [cv setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [cv setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self addSubview:cv];
    
    UILabel *l = [UILabel new];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    [l setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [l setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
    [l setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [cv addSubview:l];
    
    UILabel *dl = [UILabel new];
    dl.translatesAutoresizingMaskIntoConstraints = NO;
    [dl setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [dl setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [cv addSubview:dl];
    
    self.selectedBackgroundView = sv;
    self.contentView = cv;
    self.textLabel = l;
    self.detailTextLabel = dl;
    
    // Now let's setup our fonts and shiz
    self.textLabel.font = [UIFont boldSystemFontOfSize:17];
    FXFormLabelSetMinFontSize(self.textLabel, FXFormFieldMinFontSize);
    self.detailTextLabel.font = [UIFont systemFontOfSize:17];
    FXFormLabelSetMinFontSize(self.detailTextLabel, FXFormFieldMinFontSize);
    
    _selectionStyle = FXFormViewSelectionStyleDefault;
    _viewStyle = FXFormViewStyleDefault;
    _accessoryType = FXFormViewAccessoryNone;
}

- (void)update {
}

- (void)didSelectWithView:(__unused UIView *)view withViewController:(__unused UIViewController *)controller withFormController:(__unused FXFormController *)formController {
    
}

#pragma mark - Layout
- (void)updateConstraints {
    [super updateConstraints];
    
    UIView *av = self.accessoryView;
    UIView *cv = self.contentView;
    UILabel *l = self.textLabel;
    UILabel *dl = self.detailTextLabel;
    
    NSMutableDictionary *views = [NSDictionaryOfVariableBindings(cv, l, dl) mutableCopy];
    if (av) {
        views[@"av"] = av;
    }
    if (!av) {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[cv]-|" options:0 metrics:nil views:views]];
    }
    else {
        [av setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [av setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[cv][av]-|"
                                                                     options:NSLayoutFormatAlignAllCenterY
                                                                     metrics:nil views:views]];
    }
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[cv]-|" options:0 metrics:nil views:views]];
    
    switch (self.viewStyle) {
        case FXFormViewStyleValue1:
        case FXFormViewStyleValue2:
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[l]-[dl]-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l]-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[dl]-|" options:0 metrics:nil views:views]];
            break;
        case FXFormViewStyleSubtitle:
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[l]-<=0@999-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[dl]-<=0@999-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l][dl]->=0@999-|" options:0 metrics:nil views:views]];
            break;
        case FXFormViewStyleDefault:
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l]-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[l]-<=0@999-|" options:0 metrics:nil views:views]];
    }
}


#pragma mark - IB Inspect
- (void)prepareForInterfaceBuilder {
    self.viewStyle = self.style;
    self.accessoryType = self.accessory;
    self.contentView.backgroundColor = [UIColor greenColor];
    self.textLabel.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:.3f];
    self.detailTextLabel.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:.3f];
    self.textLabel.text = self.textLabelText;
    self.detailTextLabel.text = self.detailTextLabelText;
    self.accessoryView.backgroundColor = [UIColor redColor];
    [self setNeedsUpdateConstraints];
}
@end


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



@interface FXFormTextFieldView() <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, assign) BOOL returnKeyOverridden;
@end

@implementation FXFormTextFieldView

- (void)setup {
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
    [l setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[l]-[tf]|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tf]|" options:0 metrics:nil views:views]];
}

- (void)update {
    [super update];
    
    self.textLabel.text = self.field.title;
    self.textField.placeholder = [self.field.placeholder fieldDescription];
    self.textField.text = [self.field fieldDescription];
    
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.textAlignment = [self.field.title length]? NSTextAlignmentRight: NSTextAlignmentLeft;
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

#pragma mark - TextField
- (BOOL)textFieldShouldBeginEditing:(__unused UITextField *)textField {
    //welcome to hacksville, population: you
    if (!self.returnKeyOverridden) {
        //get return key type
        UIReturnKeyType returnKeyType = UIReturnKeyDone;
//        UITableViewCell <FXFormFieldCell> *nextCell = [self nextCell];
//        if ([nextCell canBecomeFirstResponder])
        {
//            returnKeyType = UIReturnKeyNext;
        }
        
        self.textField.returnKeyType = returnKeyType;
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(__unused UITextField *)textField {
    [self.textField selectAll:nil];
}

- (void)textDidChange {
    [self updateFieldValue];
}

- (BOOL)textFieldShouldReturn:(__unused UITextField *)textField {
    if (self.textField.returnKeyType == UIReturnKeyNext) {
//        [[self nextCell] becomeFirstResponder];
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
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tv]|" options:0 metrics:nil views:views]];
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
        [self.pickerView selectRow:index inComponent:0 animated:NO];
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
    return [self.field optionCount];
}

- (NSString *)pickerView:(__unused UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(__unused NSInteger)component {
    return [self.field optionDescriptionAtIndex:row];
}

- (void)pickerView:(__unused UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(__unused NSInteger)component {
    [self.field setOptionSelected:YES atIndex:row];
    self.detailTextLabel.text = [self.field fieldDescription] ?: [self.field.placeholder fieldDescription];
    
    if (self.field.action) self.field.action(self);
}

@end



@interface FXFormImagePickerView () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, strong, readwrite) UIImagePickerController *imagePickerController;
@property (nonatomic, weak, readwrite) UIViewController *controller;
@end

@implementation FXFormImagePickerView

#pragma mark - View Cycle
- (void)setup {
    [super setup];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.accessoryView = imageView;
}

- (void)update {
    [super update];
    
    self.textLabel.text = self.field.title;
    self.imagePickerView.image = [self imageValue];
}

- (void)didSelectWithView:(UIView *)view withViewController:(UIViewController *)controller withFormController:(FXFormController *)formController {
    [FXFormsFirstResponder(view) resignFirstResponder];
    [formController deselectRowAtIndexPath:nil animated:YES];
    
    if (!TARGET_IPHONE_SIMULATOR && ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [controller presentViewController:self.imagePickerController animated:YES completion:nil];
    }
    else if ([UIAlertController class]) {
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
    else {
        self.controller = controller;
        [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Take Photo", nil), NSLocalizedString(@"Photo Library", nil), nil] showInView:controller.view];
    }
}

- (void)dealloc {
    _imagePickerController.delegate = nil;
}

#pragma mark - Layout 
- (void)updateConstraints {
    [super updateConstraints];
    
    UIView *av = self.accessoryView;
    NSDictionary *views = NSDictionaryOfVariableBindings(av);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[av]-|" options:0 metrics:nil views:views]];
    [av addConstraint:[NSLayoutConstraint constraintWithItem:av attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:av attribute:NSLayoutAttributeHeight multiplier:1.f constant:0.f]];
}

#pragma mark - Helpers
- (UIImage *)imageValue {
    if (self.field.value) {
        return self.field.value;
    }
    else if (self.field.placeholder) {
        UIImage *placeholderImage = self.field.placeholder;
        if ([placeholderImage isKindOfClass:[NSString class]]) {
            placeholderImage = [UIImage imageNamed:self.field.placeholder];
        }
        return placeholderImage;
    }
    return nil;
}

- (UIImagePickerController *)imagePickerController {
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
        _imagePickerController.allowsEditing = YES;
    }
    return _imagePickerController;
}

- (UIImageView *)imagePickerView {
    return (UIImageView *)self.accessoryView;
}

#pragma mark - ImageController delegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.field.value = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    if (self.field.action) self.field.action(self);
    [self update];
}

- (void)actionSheet:(__unused UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    switch (buttonIndex) {
        case 0: {
            sourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        }
        case 1: {
            sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        }
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        self.imagePickerController.sourceType = sourceType;
        [self.controller presentViewController:self.imagePickerController animated:YES completion:nil];
    }
    
    self.controller = nil;
}

@end


@interface FXFormSliderView()
@property (nonatomic, strong, readwrite) UISlider *slider;
@end

@implementation FXFormSliderView

#pragma mark - View Cycle
- (void)setup {
    [super setup];
    
    self.slider = [[UISlider alloc] init];
    self.slider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.slider addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.slider];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)update {
    [super update];
    self.textLabel.text = self.field.title;
    self.slider.value = [self.field.value doubleValue];
}

#pragma mark - Layout
- (void)updateConstraints {
    [super updateConstraints];
    
    UILabel *l = self.textLabel;
    UILabel *dl = self.detailTextLabel;
    UISlider *s = self.slider;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(l, dl, s);
    [s setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [l setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[l]-[s]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
}

#pragma mark - Value Update
- (void)valueChanged:(UISlider *)s {
    self.field.value = @(s.value);
    if (self.field.action) self.field.action(self);
}

@end


@interface FXFormOptionSegmentsView()
@property (nonatomic, strong, readwrite) UISegmentedControl *segmentedControl;
@end

@implementation FXFormOptionSegmentsView

#pragma mark - View Cycle
- (void)setup {
    [super setup];
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
    self.segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.segmentedControl addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.segmentedControl];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)update {
    [super update];
    
    self.textLabel.text = self.field.title;
    [self.segmentedControl removeAllSegments];
    for (NSUInteger i = 0; i < [self.field optionCount]; i++) {
        [self.segmentedControl insertSegmentWithTitle:[self.field optionDescriptionAtIndex:i] atIndex:i animated:NO];
        if ([self.field isOptionSelectedAtIndex:i]) {
            [self.segmentedControl setSelectedSegmentIndex:i];
        }
    }
}

#pragma mark - Layout
- (void)updateConstraints {
    [super updateConstraints];
    
    UILabel *l = self.textLabel;
    UILabel *dl = self.detailTextLabel;
    UISegmentedControl *s = self.segmentedControl;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(l, dl, s);
    [s setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [l setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[l]-[s]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
}

#pragma mark - Value Update
- (void)valueChanged:(UISegmentedControl *)c {
    //note: this loop is to prevent bugs when field type is multiselect
    //which currently isn't supported by FXFormOptionSegmentsCell
    NSInteger selectedIndex = c.selectedSegmentIndex;
    for (NSInteger i = 0; i < (NSInteger)[self.field optionCount]; i++) {
        [self.field setOptionSelected:(selectedIndex == i) atIndex:i];
    }
    
    if (self.field.action) self.field.action(self);
}

@end
