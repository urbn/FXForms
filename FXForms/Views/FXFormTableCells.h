//
//  FXFormTableCells.h
//  BasicExample
//
//  Created by Joseph Ridenour on 2/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXFormsProtocols.h"

@interface FXFormBaseCell : UITableViewCell <FXFormFieldCell>

- (void)setUp;
- (void)update;
- (void)didSelectWithTableView:(UITableView *)tableView
                    controller:(UIViewController *)controller;
@end


@interface FXFormDefaultCell : FXFormBaseCell

@end


@interface FXFormTextFieldCell : FXFormBaseCell

@property (nonatomic, readonly) UITextField *textField;

@end


@interface FXFormTextViewCell : FXFormBaseCell

@property (nonatomic, readonly) UITextView *textView;

@end


@interface FXFormSwitchCell : FXFormBaseCell

@property (nonatomic, readonly) UISwitch *switchControl;

@end


@interface FXFormStepperCell : FXFormBaseCell

@property (nonatomic, readonly) UIStepper *stepper;

@end


@interface FXFormSliderCell : FXFormBaseCell

@property (nonatomic, readonly) UISlider *slider;

@end


@interface FXFormDatePickerCell : FXFormBaseCell

@property (nonatomic, readonly) UIDatePicker *datePicker;

@end


@interface FXFormImagePickerCell : FXFormBaseCell

@property (nonatomic, readonly) UIImageView *imagePickerView;
@property (nonatomic, readonly) UIImagePickerController *imagePickerController;

@end


@interface FXFormOptionPickerCell : FXFormBaseCell

@property (nonatomic, readonly) UIPickerView *pickerView;

@end


@interface FXFormOptionSegmentsCell : FXFormBaseCell

@property (nonatomic, readonly) UISegmentedControl *segmentedControl;

@end
