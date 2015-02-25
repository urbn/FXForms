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

@interface FXFormBaseView : UIView <FXFormFieldCell>

@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, readonly) UILabel *textLabel;
@property (nonatomic, readonly) UILabel *detailTextLabel;

@property (nonatomic, copy) NSIndexPath *indexPath;

@property (nonatomic, assign, getter=isHighlighted) IBInspectable BOOL highlighted;
@property (nonatomic, assign, getter=isSelected) IBInspectable BOOL selected;


// Methods

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
@interface FXFormDefaultView : FXFormBaseView @end

@interface FXFormTextFieldView : FXFormBaseView
@property (nonatomic, readonly) UITextField *textField;
@end

@interface FXFormTextViewView : FXFormBaseView
@property (nonatomic, readonly) UITextView *textView;
@end

@interface FXFormSwitchView : FXFormBaseView
@property (nonatomic, readonly) UISwitch *switchControl;
@end

@interface FXFormStepperView : FXFormBaseView
@property (nonatomic, readonly) UIStepper *stepper;
@end

@interface FXFormDatePickerView : FXFormBaseView
@property (nonatomic, readonly) UIDatePicker *datePicker;
@end

@interface FXFormOptionPickerView : FXFormBaseView
@property (nonatomic, readonly) UIPickerView *pickerView;
@end

@interface FXFormImagePickerView : FXFormBaseView
@property (nonatomic, readonly) UIImageView *imagePickerView;
@property (nonatomic, readonly) UIImagePickerController *imagePickerController;
@end

@interface FXFormSliderView : FXFormBaseView
@property (nonatomic, readonly) UISlider *slider;
@end

@interface FXFormOptionSegmentsView : FXFormBaseView
@property (nonatomic, readonly) UISegmentedControl *segmentedControl;
@end

