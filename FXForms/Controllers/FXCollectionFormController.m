//
//  FXCollectionFormController.m
//  BasicExample
//
//  Created by Joseph Ridenour on 2/20/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXCollectionFormController.h"
#import "FXFormsProtocols.h"
#import "FXFormsDefines.h"
#import "FXFormController_Private.h"
#import "FXFormField.h"
#import "FXFormModels.h"

#import "FXFormBaseView.h"

const NSInteger kFXFormViewTag = 8675309;

@interface FXFormCollectionCell : UICollectionViewCell
@property (nonatomic, strong) FXFormBaseView *formView;
@end

@implementation FXFormCollectionCell

- (void)setFormView:(FXFormBaseView *)formView {
    if ([_formView isEqual:formView]) {
        return;
    }
    
    if (_formView) {
        [_formView removeFromSuperview];
    }
    
    _formView = formView;
    
    if (formView) {
        formView.backgroundColor = [UIColor redColor];
        formView.translatesAutoresizingMaskIntoConstraints = NO;
        [formView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [self.contentView addSubview:formView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(formView);
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[formView]-|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[formView]-|" options:0 metrics:nil views:views]];
        [self invalidateIntrinsicContentSize];
    }
}

@end

@implementation FXCollectionFormController

- (instancetype)init {
    if ((self = [super init])) {
        self.cellClassesForFieldTypes = [@{FXFormFieldTypeDefault : [FXFormDefaultView class]} mutableCopy];
    }
    return self;
}

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    self.scrollView = collectionView;
    
    [self.cellClassesForFieldTypes enumerateKeysAndObjectsUsingBlock:^(__unused NSString *type, Class obj, __unused BOOL *stop) {
        [collectionView registerClass:[FXFormCollectionCell class] forCellWithReuseIdentifier:NSStringFromClass(obj)];
    }];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
//    [self.collectionView reloadData];
}

- (void)setDelegate:(id<FXFormControllerDelegate>)delegate {
    [super setDelegate:delegate];
    
    //force table to update respondsToSelector: cache
    self.collectionView.delegate = nil;
    self.collectionView.delegate = self;
}

- (void)dealloc {
    _collectionView.dataSource = nil;
    _collectionView.delegate = nil;
}

#pragma mark - Overrides 
- (FXFormBaseView *)cellForField:(FXFormField *)field
{
    //don't recycle cells - it would make things complicated
    Class cellClass = [self cellClassForField:field];
    NSString *nibName = NSStringFromClass(cellClass);
    if ([[NSBundle mainBundle] pathForResource:nibName ofType:@"nib"])
    {
        //load cell from nib
        return [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] firstObject];
    }
    else
    {
        //don't recycle cells - it would make things complicated
        return [[cellClass alloc] init];
    }
}


#pragma mark - CollectionView DataSource
- (NSInteger)numberOfSectionsInCollectionView:(__unused UICollectionView *)collectionView {
    return [self numberOfSections];
}

- (NSInteger)collectionView:(__unused UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self numberOfFieldsInSection:section];
}

- (void)configureView:(FXFormBaseView *)view forIndexPath:(NSIndexPath *)indexPath {
    FXFormField *field = [self fieldForIndexPath:indexPath];
    
    //configure cell before setting field (in case it affects how value is displayed)
    [field.cellConfig enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, id value, __unused BOOL *stop) {
        [view setValue:value forKeyPath:keyPath];
    }];
    
    //set form field
    view.field = field;
    
    //configure cell after setting field as well (not ideal, but allows overriding keyboard attributes, etc)
    [field.cellConfig enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, id value, __unused BOOL *stop) {
        [view setValue:value forKeyPath:keyPath];
    }];
}

//- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(FXFormCollectionCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
//    [self configureView:cell.formView forIndexPath:indexPath];
//    //forward to delegate
//    if ([self.delegate respondsToSelector:_cmd])
//    {
//        [(id<UICollectionViewDelegate>)self.delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
//    }
//}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FXFormField *field = [self fieldForIndexPath:indexPath];
    FXFormCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([self cellClassForField:field]) forIndexPath:indexPath];
    
    if ([cell.contentView respondsToSelector:@selector(layoutMargins)]) {
        [cell.contentView setValue:[NSValue valueWithUIEdgeInsets:UIEdgeInsetsZero] forKey:@"layoutMargins"];
    }
    
    FXFormBaseView *v = [self cellForField:field];
    [cell setFormView: v];
    [self configureView:v forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor whiteColor];
    
    return cell;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(__unused UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//    FXFormBaseView *v = [self cellForField:[self fieldForIndexPath:indexPath]];
//    [self configureView:v forIndexPath:indexPath];
//    
//    NSString *className = NSStringFromClass(v.class);
//    [v setNeedsLayout];
//    [v layoutIfNeeded];
//    
//    NSNumber *cachedHeight = @([v systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
//    self.cellHeightCache[className] = cachedHeight;
//    
//    return CGSizeMake(collectionView.frame.size.width, [cachedHeight floatValue]);
//}

@end


@interface FXFormCollectionViewController ()
@property (nonatomic, strong) FXCollectionFormController *formController;
@end

@implementation FXFormCollectionViewController
@synthesize collectionView = _collectionView;
@synthesize field = _field;

- (void)dealloc
{
    _formController.delegate = nil;
}

- (void)setField:(FXFormField *)field
{
    _field = field;
    
    id<FXForm> form = nil;
    if (field.options)
    {
        form = [[FXOptionsForm alloc] initWithField:field];
    }
    else if ([field isCollectionType])
    {
        form = [[FXTemplateForm alloc] initWithField:field];
    }
    else if ([field.valueClass conformsToProtocol:@protocol(FXForm)])
    {
        if (!field.value && ![field.valueClass isSubclassOfClass:FXFormClassFromString(@"NSManagedObject")])
        {
            //create a new instance of the form automatically
            field.value = [[field.valueClass alloc] init];
        }
        form = field.value;
    }
    else
    {
        [NSException raise:FXFormsException format:@"FXFormViewController field value must conform to FXForm protocol"];
    }
    
    self.formController.parentFormController = field.formController;
    self.formController.form = form;
}

- (FXCollectionFormController *)formController {
    if (!_formController) {
        _formController = [[FXCollectionFormController alloc] init];
        _formController.delegate = self;
    }
    return _formController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.collectionView) {
        UICollectionViewFlowLayout *l = [UICollectionViewFlowLayout new];
        l.estimatedItemSize = CGSizeMake(self.view.bounds.size.width, 100.f);
        self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                                 collectionViewLayout:l];
    }
    if (!self.collectionView.superview) {
        self.view = self.collectionView;
    }
}

- (void)setCollectionView:(UICollectionView *)collectionView {
    _collectionView = collectionView;
    self.formController.collectionView = collectionView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSIndexPath *selected = [[self.collectionView indexPathsForSelectedItems] firstObject];
    if (selected) {
        [self.collectionView reloadData];
        [self.collectionView selectItemAtIndexPath:selected animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        [self.collectionView deselectItemAtIndexPath:selected animated:YES];
    }
}

@end

