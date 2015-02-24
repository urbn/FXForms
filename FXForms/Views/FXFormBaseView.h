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
- (void)setup;

/**
 *  This is called whenever the cell data updates.   (i.e when the cell comes on screen).
 */
- (void)update;


- (void)didSelectWithView:(UIView *)view withViewController:(UIViewController *)controller withFormController:(FXFormController *)formController;

@end


// Subclasses
@interface FXFormDefaultView : FXFormBaseView @end
@interface FXFormTextFieldView : FXFormBaseView
@property (nonatomic, readonly) UITextField *textField;
@end
