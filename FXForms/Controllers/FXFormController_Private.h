//
//  FXFormController_Private.h
//  BasicExample
//
//  Created by Joseph Ridenour on 2/20/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma clang diagnostic ignored "-Wreceiver-is-weak"
#pragma clang diagnostic ignored "-Wconversion"
#pragma clang diagnostic ignored "-Wgnu"


// Views
#import "FXFormBaseView.h"
#import "FXFormDefaultView.h"


@class FXFormSection;

@interface FXFormController ()

@property (nonatomic, weak) UIScrollView *scrollView;

@property (nonatomic, strong) NSMutableDictionary *cellHeightCache;
@property (nonatomic, strong) NSMutableDictionary *cellClassesForFieldTypes;
@property (nonatomic, strong) NSMutableDictionary *cellClassesForFieldClasses;
@property (nonatomic, strong) NSMutableDictionary *controllerClassesForFieldTypes;
@property (nonatomic, strong) NSMutableDictionary *controllerClassesForFieldClasses;

- (FXFormSection *)sectionAtIndex:(NSUInteger)index;
- (id <FXFormFieldCell>)cellForField:(FXFormField *)field;
- (UIViewController *)viewController;

@end
