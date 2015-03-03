//
//  FXFormImagePickerView.m
//  BasicExample
//
//  Created by Joseph Ridenour on 3/3/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormImagePickerView.h"
#import "FXFormController.h"
#import "FXFormsDefines.h"
#import "FXFormField.h"

@interface FXFormImagePickerView () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, strong, readwrite) UIImagePickerController *imagePickerController;
@property (nonatomic, weak, readwrite) UIViewController *controller;
@end

@implementation FXFormImagePickerView

#pragma mark - View Cycle
- (void)setup {
    [super setup];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.accessoryView = imageView;
}

- (void)update {
    [super update];
    
    self.textLabel.text = self.field.title;
    self.imagePickerView.image = [self imageValue];
}

- (void)didSelectWithView:(UIView *)view withViewController:(UIViewController *)controller withFormController:(FXFormController *)formController {
    [FXFormsFirstResponder(view) resignFirstResponder];
    [formController deselectRowAtIndexPath:nil animated:YES];
    
    if (!TARGET_IPHONE_SIMULATOR && ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [controller presentViewController:self.imagePickerController animated:YES completion:nil];
    }
    else if ([UIAlertController class]) {
        UIAlertControllerStyle style = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)? UIAlertControllerStyleAlert: UIAlertControllerStyleActionSheet;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:style];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Take Photo", nil) style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self actionSheet:nil didDismissWithButtonIndex:0];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Photo Library", nil) style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self actionSheet:nil didDismissWithButtonIndex:1];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:NULL]];
        
        self.controller = controller;
        [controller presentViewController:alert animated:YES completion:NULL];
    }
    else {
        self.controller = controller;
        [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Take Photo", nil), NSLocalizedString(@"Photo Library", nil), nil] showInView:controller.view];
    }
}

- (void)dealloc {
    _imagePickerController.delegate = nil;
}

#pragma mark - Layout
- (void)updateConstraints {
    [super updateConstraints];
    
    UIView *av = self.accessoryView;
    NSDictionary *views = NSDictionaryOfVariableBindings(av);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[av]-|" options:0 metrics:nil views:views]];
    [av addConstraint:[NSLayoutConstraint constraintWithItem:av attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:av attribute:NSLayoutAttributeHeight multiplier:1.f constant:0.f]];
}

#pragma mark - Helpers
- (UIImage *)imageValue {
    if (self.field.value) {
        return self.field.value;
    }
    else if (self.field.placeholder) {
        UIImage *placeholderImage = self.field.placeholder;
        if ([placeholderImage isKindOfClass:[NSString class]]) {
            placeholderImage = [UIImage imageNamed:self.field.placeholder];
        }
        return placeholderImage;
    }
    return nil;
}

- (UIImagePickerController *)imagePickerController {
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
        _imagePickerController.allowsEditing = YES;
    }
    return _imagePickerController;
}

- (UIImageView *)imagePickerView {
    return (UIImageView *)self.accessoryView;
}

#pragma mark - ImageController delegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.field.value = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    if (self.field.action) self.field.action(self);
    [self update];
}

- (void)actionSheet:(__unused UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    switch (buttonIndex) {
        case 0: {
            sourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        }
        case 1: {
            sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        }
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        self.imagePickerController.sourceType = sourceType;
        [self.controller presentViewController:self.imagePickerController animated:YES completion:nil];
    }
    
    self.controller = nil;
}

@end

