//
//  FXCollectionFormController.h
//  BasicExample
//
//  Created by Joseph Ridenour on 2/20/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXFormController.h"

@interface FXCollectionFormController : FXFormController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end
