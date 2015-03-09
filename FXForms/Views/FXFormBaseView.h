//
//  FXFormBaseView.h
//  BasicExample
//
//  Created by Joseph Ridenour on 2/23/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXFormsProtocols.h"

/**
 *  This is an abstract class that will pave the way for all of our fxform field subclasses.
 *  Within this class we'll do a little work to mimic some of the useful built in features of 
 *  UITabelViewCell.
 */
@class FXFormController;

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

typedef NS_ENUM(NSInteger, FXFormViewAccessoryType) {
    FXFormViewAccessoryNone,
    FXFormViewAccessoryDisclosureIndicator,
    FXFormViewAccessoryDetailDisclosureIndicator,
    FXFormViewAccessoryCheckmark,
};

@interface FXFormBaseView : UIView <FXFormFieldCell>

@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, readonly) UILabel *textLabel;
@property (nonatomic, readonly) UILabel *detailTextLabel;

@property (nonatomic, strong) UIView *selectedBackgroundView;
@property (nonatomic, strong) UIView *accessoryView;

@property (nonatomic, copy) NSIndexPath *indexPath;

@property (nonatomic, strong) UIColor *dividerColor;    // This is temporary, and will go away eventually

@property (nonatomic, assign, getter=isHighlighted) IBInspectable BOOL highlighted;
@property (nonatomic, assign, getter=isSelected) IBInspectable BOOL selected;

- (void)setAccessoryImage:(UIImage *)image forType:(FXFormViewAccessoryType)type UI_APPEARANCE_SELECTOR;

@property (nonatomic, assign) FXFormViewAccessoryType accessoryType;
@property (nonatomic, assign) FXFormViewSelectionStyle selectionStyle;
@property (nonatomic, assign) FXFormViewStyle viewStyle;

// Methods
- (UIResponder<FXFormFieldCell> *)nextCell;

/**
 *  This is our `sharedInit` method.  Any initialization you want to do for your
 *  subclass goes in here.  Make sure to call super.
 */
- (void)setup NS_REQUIRES_SUPER;

/**
 *  This is called whenever the cell data updates.   (i.e when the cell comes on screen).
 */
- (void)update NS_REQUIRES_SUPER;


- (void)didSelectWithView:(UIView *)view withViewController:(UIViewController *)controller withFormController:(FXFormController *)formController;

@end


// Subclasses
@interface FXFormSliderView : FXFormBaseView
@property (nonatomic, readonly) UISlider *slider;
@end

@interface FXFormOptionSegmentsView : FXFormBaseView
@property (nonatomic, readonly) UISegmentedControl *segmentedControl;
@end

