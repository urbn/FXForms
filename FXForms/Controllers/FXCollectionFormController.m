//
//  FXCollectionFormController.m
//  BasicExample
//
//  Created by Joseph Ridenour on 2/20/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXCollectionFormController.h"
#import "FXFormController_Private.h"


@implementation FXCollectionFormController

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    self.scrollView = collectionView;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView reloadData];
}

- (void)setDelegate:(id<FXFormControllerDelegate>)delegate {
    [super setDelegate:delegate];
    
    //force table to update respondsToSelector: cache
    self.collectionView.delegate = nil;
    self.collectionView.delegate = self;
}

- (UIViewController *)tableViewController
{
    id responder = self.collectionView;
    while (responder)
    {
        if ([responder isKindOfClass:[UIViewController class]])
        {
            return responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

- (void)dealloc {
    _collectionView.dataSource = nil;
    _collectionView.delegate = nil;
}

#pragma mark - CollectionView DataSource
- (NSInteger)numberOfSectionsInCollectionView:(__unused UICollectionView *)collectionView {
    return [self numberOfSections];
}

- (NSInteger)collectionView:(__unused UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self numberOfFieldsInSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CELLID" forIndexPath:indexPath];
#warning FIX THIS
    return cell;
}

@end
