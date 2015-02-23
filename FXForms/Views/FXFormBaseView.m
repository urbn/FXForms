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

IB_DESIGNABLE @interface FXFormBaseView()
@property (nonatomic, strong, readwrite) UIView *contentView;
@property (nonatomic, strong, readwrite) UILabel *textLabel;
@property (nonatomic, strong, readwrite) UILabel *detailTextLabel;

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
    [self invalidateIntrinsicContentSize];
    [self update];
}

#pragma mark - Flow
- (void)setup {
    UIView *cv = [UIView new];
    cv.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:cv];
    
    UILabel *l = [UILabel new];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    [l setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [l setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [cv addSubview:l];
    
    UILabel *dl = [UILabel new];
    dl.translatesAutoresizingMaskIntoConstraints = NO;
    [dl setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [cv addSubview:dl];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(cv, l, dl);
    NSArray *h = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[cv]-|" options:0 metrics:nil views:views];
    NSArray *v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[cv]-|" options:0 metrics:nil views:views];
    [self addConstraints:[h arrayByAddingObjectsFromArray:v]];
    
    [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[l]-|" options:0 metrics:nil views:views]];
    [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[dl]-|" options:0 metrics:nil views:views]];
    [cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l]-[dl]-|" options:0 metrics:nil views:views]];
    
    self.contentView = cv;
    self.textLabel = l;
    self.detailTextLabel = dl;
    
    // Now let's setup our fonts and shiz
    self.textLabel.font = [UIFont boldSystemFontOfSize:17];
    FXFormLabelSetMinFontSize(self.textLabel, FXFormFieldMinFontSize);
    self.detailTextLabel.font = [UIFont systemFontOfSize:17];
    FXFormLabelSetMinFontSize(self.detailTextLabel, FXFormFieldMinFontSize);
}

- (void)update {
    
}

- (void)didSelectWithView:(UIView *)view controller:(UIViewController *)vc {
    
}

#pragma mark - IB Inspect
- (void)prepareForInterfaceBuilder {
    self.contentView.backgroundColor = [UIColor greenColor];
    self.textLabel.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:.3f];
    self.detailTextLabel.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:.3f];
    self.textLabel.text = self.textLabelText;
    self.detailTextLabel.text = self.detailTextLabelText;
}
@end




@implementation FXFormDefaultView

- (void)update
{
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription];
    
    if ([self.field.type isEqualToString:FXFormFieldTypeLabel])
    {
//        self.accessoryType = UITableViewCellAccessoryNone;
        if (!self.field.action)
        {
//            self.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    else if ([self.field isSubform] || self.field.segue)
    {
//        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeBoolean] || [self.field.type isEqualToString:FXFormFieldTypeOption])
    {
        self.detailTextLabel.text = nil;
//        self.accessoryType = [self.field.value boolValue]? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
    }
    else if (self.field.action)
    {
//        self.accessoryType = UITableViewCellAccessoryNone;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    else
    {
//        self.accessoryType = UITableViewCellAccessoryNone;
//        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

@end
