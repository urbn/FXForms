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
@interface FXFormBaseView : UIView <FXFormFieldCell>

@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, readonly) UILabel *textLabel;
@property (nonatomic, readonly) UILabel *detailTextLabel;


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


- (void)didSelectWithView:(UIView *)view controller:(UIViewController *)vc;

@end


// Subclasses
@interface FXFormDefaultView : FXFormBaseView @end

