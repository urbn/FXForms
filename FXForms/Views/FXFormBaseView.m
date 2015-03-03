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

IB_DESIGNABLE @interface FXFormBaseView()
@property (nonatomic, strong, readwrite) UIView *contentView;
@property (nonatomic, strong, readwrite) UILabel *textLabel;
@property (nonatomic, strong, readwrite) UILabel *detailTextLabel;

@property (nonatomic, strong) NSMutableDictionary *accessoryImagesMap;

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

- (void)setAccessoryImage:(UIImage *)image forType:(FXFormViewAccessoryType)type {
    if (!image) {
        [self.accessoryImagesMap removeObjectForKey:@(type)];
    }
    else {
        self.accessoryImagesMap[@(type)] = image;
    }
}

#pragma mark - Getters
- (UIView *)accessoryView {
    if (!_accessoryView && self.accessoryType != FXFormViewAccessoryNone) {
        _accessoryView = [[UIImageView alloc] initWithImage:[self imageForAccessoryType:self.accessoryType]];
        _accessoryView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_accessoryView];
    }
    return _accessoryView;
}

- (UIImage *)imageForAccessoryType:(FXFormViewAccessoryType)type {
    if (self.accessoryImagesMap[@(type)]) {
        return self.accessoryImagesMap[@(type)];
    }
    
    CGRect rect = CGRectMake(0, 0, 20.f, 20.f);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    rect = CGRectInset(rect, 5.f, 5.f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextClearRect(context, rect);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 2.f);
    
    CGFloat minX = CGRectGetMinX(rect), maxX = CGRectGetMaxX(rect);
    CGFloat minY = CGRectGetMinY(rect), maxY = CGRectGetMaxY(rect);
    CGFloat midX = CGRectGetMidX(rect), midY = CGRectGetMidY(rect);
    
    if (type == FXFormViewAccessoryCheckmark) { // Checkmark
        CGContextMoveToPoint(context, minX, maxY - (maxY / 4.f));
        CGContextAddLineToPoint(context, (midX * 3.f) / 4.f, maxY);
        CGContextAddLineToPoint(context, maxX, minY);
        CGContextStrokePath(context);
    } else if (type == FXFormViewAccessoryDisclosureIndicator) {    // Side ways arrow
        CGContextMoveToPoint(context, midX, minY);
        CGContextAddLineToPoint(context, maxX, midY);
        CGContextAddLineToPoint(context, midX, maxY);
        CGContextStrokePath(context);
    } else if (type == FXFormViewAccessoryDetailDisclosureIndicator) { // Circle with plus in the middle
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
    self.accessoryImagesMap = [NSMutableDictionary dictionary];
    
    UIView *sv = [[UIView alloc] initWithFrame:self.bounds];
    sv.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    sv.alpha = 0.f;
    sv.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5f];
    [self addSubview:sv];
    
    UIView *cv = [UIView new];
    FXFormSetLayoutMarginsIfPossible(cv, UIEdgeInsetsMake(8.f, 15.f, 8.f, 15.f));
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

- (void)update { /* Override */ }

- (void)didSelectWithView:(__unused UIView *)view withViewController:(__unused UIViewController *)controller withFormController:(__unused FXFormController *)formController { /* Override */}

#pragma mark - Layout
- (void)updateConstraints {
    [super updateConstraints];
    
    UIView *av = self.accessoryView;
    UIView *cv = self.contentView;
    UILabel *l = self.textLabel;
    UILabel *dl = self.detailTextLabel;
    
    NSMutableDictionary *views = [NSDictionaryOfVariableBindings(cv, l, dl) mutableCopy];
    NSDictionary *metrics = @{@"minLabelW": @(FXFormFieldMinLabelWidth),@"maxLabelW": @(FXFormFieldMaxLabelWidth)};
    if (av) {
        views[@"av"] = av;
    }
    if (!av) {
        FXFormSetLayoutMarginsIfPossible(self, UIEdgeInsetsZero);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[cv]-|" options:0 metrics:nil views:views]];
    }
    else {
        FXFormSetLayoutMarginsIfPossible(self, UIEdgeInsetsMake(0, 0, 0, 10.f));
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
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[l(>=minLabelW,<=maxLabelW)]-[dl]-|" options:0 metrics:metrics views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l]-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[dl]-|" options:0 metrics:nil views:views]];
            break;
        case FXFormViewStyleSubtitle:
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[l]-|" options:0 metrics:metrics views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[dl]-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l][dl]->=8@999-|" options:0 metrics:nil views:views]];
            break;
        case FXFormViewStyleDefault:
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l]->=8@999-|" options:0 metrics:nil views:views]];
            [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[l(>=minLabelW,<=maxLabelW)]-<=0@999-|" options:0 metrics:metrics views:views]];
    }
}

#pragma mark - Responders
- (UIResponder<FXFormFieldCell> *)nextCell {
    return [[[self field] formController] nextCellForCell:self.superview.superview];
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
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[l]-[s]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[l][s]-|" options:0 metrics:nil views:views]];
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
    [s setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [s setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [l setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [l setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[l]-[s]-|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[s]-|" options:0 metrics:nil views:views]];
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
