//
//  FXFormImagePickerView.h
//  BasicExample
//
//  Created by Joseph Ridenour on 3/3/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormBaseView.h"

@interface FXFormImagePickerView : FXFormBaseView
@property (nonatomic, readonly) UIImageView *imagePickerView;
@property (nonatomic, readonly) UIImagePickerController *imagePickerController;
@end
