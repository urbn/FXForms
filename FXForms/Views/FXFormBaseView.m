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
#import "FXTableFormController.h"

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
@property (nonatomic, assign) NSInteger viewStyle;

// Funsies
@property (nonatomic, copy) IBInspectable NSString *textLabelText;
@property (nonatomic, copy) IBInspectable NSString *detailTextLabelText;
@end


@implementation FXFormBaseView
@synthesize field = _field;


#pragma mark - Init
- (instancetype)init {
    if ((self = [super init])) {
        [self setup];
    }
    return self;
}

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

- (void)setField:(FXFormField *)field {
    _field = field;
    [self update];
}

- (void)setAccessoryType:(FXFormViewAccessoryType)accessoryType {
    if (_accessoryType == accessoryType) {
        return;
    }
    _accessoryType = accessoryType;
    if (accessoryType == FXFormViewAccessoryNone) {
        [_accessoryView removeFromSuperview];
        _accessoryView = nil;
    }
    [self setNeedsUpdateConstraints];
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    
    self.textLabel.highlighted =
    self.detailTextLabel.highlighted = selected;
    self.selectedBackgroundView.alpha = selected ? 1.f : 0.f;
}

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    
    self.textLabel.highlighted =
    self.detailTextLabel.highlighted = highlighted;
    self.selectedBackgroundView.alpha = highlighted ? 1.f : 0.f;
}

- (void)setViewStyle:(NSInteger)viewStyle {
    if (_viewStyle == viewStyle) {
        return;
    }
    _viewStyle = viewStyle;
    self.detailTextLabel.hidden = viewStyle == FXFormViewStyleDefault;
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
        
    } else if (self.accessoryType == FXFormViewAccessoryDisclosureIndicator) {
        CGContextMoveToPoint(context, midX / 2.f, minY);
        CGContextAddLineToPoint(context, maxX, midY);
        CGContextAddLineToPoint(context, midX / 2.f, maxY);
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
    
    UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if ([i respondsToSelector:@selector(imageWithRenderingMode:)]) {
        i = [i performSelector:@selector(imageWithRenderingMode:) withObject:@2];
    }
    
    return i;
}

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
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cv]|" options:0 metrics:nil views:views]];
    }
    else {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cv][av(<=20)]|"
                                                                     options:NSLayoutFormatAlignAllCenterY
                                                                     metrics:nil views:views]];
    }
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[cv]|" options:0 metrics:nil views:views]];

    switch (self.viewStyle) {
        case FXFormViewStyleValue1:
        case FXFormViewStyleValue2:
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[l]-[dl]|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l]-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[dl]-|" options:0 metrics:nil views:views]];
            break;
        case FXFormViewStyleSubtitle:
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[l]-<=0@999-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[dl]-<=0@999-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l][dl]-|" options:0 metrics:nil views:views]];
            break;
        default:
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l]-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[l]-<=0@999-|" options:0 metrics:nil views:views]];
    }
}

#pragma mark - Flow
- (void)setup {
    UIView *sv = [[UIView alloc] initWithFrame:self.bounds];
    sv.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    sv.alpha = 0.f;
    sv.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5f];
    [self addSubview:sv];
    
    UIView *cv = [UIView new];
    cv.layer.borderWidth = 1.f;
    cv.translatesAutoresizingMaskIntoConstraints = NO;
    [cv setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [cv setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self addSubview:cv];
    
    UILabel *l = [UILabel new];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    [l setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [l setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
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
    
    [self setNeedsUpdateConstraints];
    
    // Now let's setup our fonts and shiz
    self.textLabel.font = [UIFont boldSystemFontOfSize:17];
    FXFormLabelSetMinFontSize(self.textLabel, FXFormFieldMinFontSize);
    self.detailTextLabel.font = [UIFont systemFontOfSize:17];
    FXFormLabelSetMinFontSize(self.detailTextLabel, FXFormFieldMinFontSize);
    _selectionStyle = FXFormViewSelectionStyleDefault;
}

- (void)update {
    
}

- (void)didSelectWithView:(__unused UIView *)view withViewController:(__unused UIViewController *)controller withFormController:(__unused FXFormController *)formController {
    
}

#pragma mark - IB Inspect
- (void)prepareForInterfaceBuilder {
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
        self.accessoryType = [self.field.value boolValue]? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
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
    if ([self.field.type isEqualToString:FXFormFieldTypeBoolean] || [self.field.type isEqualToString:FXFormFieldTypeOption]) {
        [FXFormsFirstResponder(view) resignFirstResponder];
        self.field.value = @(![self.field.value boolValue]);
        if (self.field.action) self.field.action(self);
        self.accessoryType = [self.field.value boolValue]? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
        if ([self.field.type isEqualToString:FXFormFieldTypeOption])
        {
            NSIndexPath *indexPath = self.indexPath;
            if (indexPath)
            {
                //reload section, in case fields are linked
                [formController performUpdates:nil withCompletion:nil];
//                [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
        else
        {
            //deselect the cell
            [formController deselectRowAtIndexPath:nil animated:YES];
        }
    }
    else if (self.field.action && (![self.field isSubform] || !self.field.options))
    {
        //action takes precendence over segue or subform - you can implement these yourself in the action
        //the exception is for options fields, where the action will be called when the option is tapped
        //TODO: do we need to make other exceptions? Or is there a better way to handle actions for subforms?
        [FXFormsFirstResponder(view) resignFirstResponder];
        self.field.action(self);
        [formController deselectRowAtIndexPath:nil animated:YES];
    }
    else if (self.field.segue && [self.field.segue class] != self.field.segue)
    {
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
    else if ([self.field isSubform])
    {
        [FXFormsFirstResponder(view) resignFirstResponder];
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

@interface FXFormTextFieldView() <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@end

@implementation FXFormTextFieldView

- (void)setup {
    self.viewStyle = FXFormViewStyleDefault;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 21)];
    self.textField.backgroundColor = [UIColor yellowColor];
    self.textField.font = [UIFont systemFontOfSize:self.textLabel.font.pointSize];
    self.textField.minimumFontSize = FXFormLabelMinFontSize(self.textLabel);
    self.textField.textColor = [UIColor colorWithRed:0.275f green:0.376f blue:0.522f alpha:1.000f];
    self.textField.delegate = self;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    [super setup];
    [self.contentView addSubview:self.textField];
    
    [self.contentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.textField action:NSSelectorFromString(@"becomeFirstResponder")]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:UITextFieldTextDidChangeNotification object:self.textField];
    
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    [super updateConstraints];
    
    UIView *l = self.textLabel;
    UITextField *tf = self.textField;
    NSDictionary *views = NSDictionaryOfVariableBindings(l, tf);
    CGFloat min = FXFormFieldMinLabelWidth;
    CGFloat max = FXFormFieldMaxLabelWidth;
    NSDictionary *metrics = @{@"max": @(max), @"min": @(min)};
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[l][tf(>=min)]-|" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tf]|" options:0 metrics:nil views:views]];
}

- (void)update {
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
    [self setNeedsUpdateConstraints];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - TextField
- (BOOL)textFieldShouldBeginEditing:(__unused UITextField *)textField {
    //welcome to hacksville, population: you
//    if (!self.returnKeyOverridden) {
//        //get return key type
//        UIReturnKeyType returnKeyType = UIReturnKeyDone;
//        UITableViewCell <FXFormFieldCell> *nextCell = [self nextCell];
//        if ([nextCell canBecomeFirstResponder])
//        {
//            returnKeyType = UIReturnKeyNext;
//        }
//        
//        self.textField.returnKeyType = returnKeyType;
//    }
    return YES;
}

- (void)textFieldDidBeginEditing:(__unused UITextField *)textField {
    [self.textField selectAll:nil];
}

- (void)textDidChange {
    [self updateFieldValue];
}

- (BOOL)textFieldShouldReturn:(__unused UITextField *)textField
{
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


