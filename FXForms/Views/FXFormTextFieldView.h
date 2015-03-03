//
//  FXFormTextFieldCell.h
//  BasicExample
//
//  Created by Joseph Ridenour on 3/3/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormBaseView.h"

@interface FXFormTextFieldView : FXFormBaseView
@property (nonatomic, readonly) UITextField *textField;

@property (nonatomic, assign) NSTextAlignment textAlignment UI_APPEARANCE_SELECTOR;
@end
