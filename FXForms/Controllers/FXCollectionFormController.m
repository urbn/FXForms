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

#import "FXFormViews.h"

@interface FXFormCollectionCell : UICollectionViewCell <FXFormFieldCell>
@property (nonatomic, strong) FXFormBaseView *formView;
@end

@interface FXFormCollectionHeaderView : UICollectionReusableView
@property (nonatomic, strong) UILabel *label;
@end

@implementation FXFormCollectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        FXFormSetLayoutMarginsIfPossible(self, UIEdgeInsetsMake(10.f, 15.f, 3.f, 0.f));
        UILabel *l = [UILabel new];
        l.translatesAutoresizingMaskIntoConstraints = NO;
        l.textColor = [UIColor darkGrayColor];
        [l setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        l.font = [UIFont systemFontOfSize:14.f];
        [self addSubview:l];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(l);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[l]-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[l]-|" options:0 metrics:nil views:views]];
        self.label = l;
    }
    return self;
}

@end

@implementation FXFormCollectionCell

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self.formView setSelected: selected];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted: highlighted];
    [self.formView setHighlighted:highlighted];
}

- (void)setFormView:(FXFormBaseView *)formView {
    if ([_formView isEqual:formView]) {
        return;
    }
    
    if (_formView) {
        [_formView removeFromSuperview];
    }
    
    _formView = formView;
    if (formView) {
        formView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:formView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(formView);
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[formView]|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[formView]|" options:0 metrics:nil views:views]];
    }
}

#pragma mark - Responder
- (BOOL)canBecomeFirstResponder {
    return [self.formView canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.formView becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [self.formView resignFirstResponder];
}

#pragma mark - Actions
- (void)delete:(__unused id)sender {
    FXFormController *formController = [[self field] formController];
    NSIndexPath *indexPath = [formController indexPathForField:[self field]];
    
    [formController performUpdates:^{
        FXFormSection *section = [formController sectionAtIndex:indexPath.section];
        [section removeFieldAtIndex:indexPath.row];
        [formController deleteRowsAtIndexPaths:@[indexPath]];
    } withCompletion:nil];
}


#pragma mark - FormFieldCell
- (void)setField:(FXFormField *)field { [self.formView setField:field]; }
- (FXFormField *)field { return self.formView.field; }

@end

@implementation FXCollectionFormController

- (instancetype)init {
    if ((self = [super init])) {
        self.cellClassesForFieldTypes = [
                                         @{
                                           FXFormFieldTypeDefault : [FXFormDefaultView class],
                                           FXFormFieldTypeURL: [FXFormTextFieldView class],
                                           FXFormFieldTypeEmail: [FXFormTextFieldView class],
                                           FXFormFieldTypePhone: [FXFormTextFieldView class],
                                           FXFormFieldTypePassword: [FXFormTextFieldView class],
                                           FXFormFieldTypeNumber: [FXFormTextFieldView class],
                                           FXFormFieldTypeFloat: [FXFormTextFieldView class],
                                           FXFormFieldTypeInteger: [FXFormTextFieldView class],
                                           FXFormFieldTypeUnsigned: [FXFormTextFieldView class],
                                           FXFormFieldTypeText : [FXFormTextFieldView class],
                                           FXFormFieldTypeNumber : [FXFormStepperView class],
                                           FXFormFieldTypeBoolean: [FXFormSwitchView class],
                                           FXFormFieldTypeLongText: [FXFormTextViewView class],
                                           
                                           FXFormFieldTypeDate: [FXFormDatePickerView class],
                                           FXFormFieldTypeTime: [FXFormDatePickerView class],
                                           FXFormFieldTypeDateTime: [FXFormDatePickerView class],
                                           
                                           FXFormFieldTypeImage: [FXFormImagePickerView class],
                                           
                                           } mutableCopy];
        self.controllerClassesForFieldTypes = [@{FXFormFieldTypeDefault: [FXFormCollectionViewController class]} mutableCopy];
    }
    return self;
}

- (void)registerCellsIfPossible {
    if (self.form && self.collectionView) {
        NSArray *allFields = [self.sections valueForKeyPath:@"@unionOfArrays.fields"];
        [self.cellClassesForFieldTypes enumerateKeysAndObjectsUsingBlock:^(__unused NSString *key, Class obj, __unused BOOL *stop) {
            [self.collectionView registerClass:[FXFormCollectionCell class] forCellWithReuseIdentifier:NSStringFromClass(obj)];
        }];
        
        [allFields enumerateObjectsUsingBlock:^(FXFormField *obj, __unused NSUInteger idx, __unused BOOL *stop) {
            Class cellClass = [self cellClassForField:obj];
            [self.collectionView registerClass:[FXFormCollectionCell class] forCellWithReuseIdentifier:NSStringFromClass(cellClass)];
        }];
        
        [self.collectionView registerClass:[FXFormCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:UICollectionElementKindSectionHeader];
    }
}

- (void)setCollectionView:(UICollectionView *)collectionView {
    _collectionView = collectionView;
    self.scrollView = collectionView;
    
    [self registerCellsIfPossible];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
}

- (void)setDelegate:(id<FXFormControllerDelegate>)delegate {
    [super setDelegate:delegate];
    
    //force table to update respondsToSelector: cache
    self.collectionView.delegate = nil;
    self.collectionView.delegate = self;
}

- (void)setForm:(id<FXForm>)form {
    [super setForm:form];
    
    [self registerCellsIfPossible];
}

#pragma mark - Overrides 
- (FXFormBaseView *)formViewForField:(FXFormField *)field {
    //don't recycle cells - it would make things complicated
    Class cellClass = [self cellClassForField:field];
    NSString *nibName = NSStringFromClass(cellClass);
    FXFormBaseView *view = nil;
    if ([[NSBundle mainBundle] pathForResource:nibName ofType:@"nib"])
    {
        //load cell from nib
        view = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] firstObject];
    }
    else {
        //don't recycle cells - it would make things complicated
        view = [[cellClass alloc] init];
    }
    
    [self configureView:view forIndexPath:[self indexPathForField:field]];
    return view;
}

- (UIView *)headerViewForSection:(NSInteger)section {
    UIView *header = (UIView *)[self sectionAtIndex:section];
    if ([header isKindOfClass:[UIView class]]) {
        return header;
    }
    else {
        header = [[FXFormCollectionHeaderView alloc] initWithFrame:CGRectZero];
        header.translatesAutoresizingMaskIntoConstraints = NO;
        ((FXFormCollectionHeaderView *)header).label.text = [[header description] uppercaseString];
        return header;
    }
}

- (id <FXFormFieldCell>)cellForField:(FXFormField *)field {
    NSIndexPath *indexPath = [self indexPathForField:field];
    return [self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([self cellClassForField:field]) forIndexPath:indexPath];
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
    
    //set form fieldfield
    view.field = field;
    
    //configure cell after setting field as well (not ideal, but allows overriding keyboard attributes, etc)
    [field.cellConfig enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, id value, __unused BOOL *stop) {
        [view setValue:value forKeyPath:keyPath];
    }];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    cell.contentView.backgroundColor = [UIColor whiteColor];
    FXFormField *field = [self fieldForIndexPath:indexPath];
    FXFormBaseView *v = [self formViewForField:field];
    [(FXFormCollectionCell *)cell setFormView: v];
    
    //forward to delegate
    if ([self.delegate respondsToSelector:_cmd]) {
        [(id<UICollectionViewDelegate>)self.delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
}

- (UICollectionViewCell *)collectionView:(__unused UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return (UICollectionViewCell *)[self cellForField:[self fieldForIndexPath:indexPath]];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    FXFormBaseView *v = [self formViewForField:[self fieldForIndexPath:indexPath]];
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)collectionViewLayout;
    
    CGFloat height = [v systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    CGSize s = CGSizeMake(collectionView.frame.size.width, height);
    s.width -= (layout.sectionInset.left + layout.sectionInset.right);
    return s;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(__unused UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    UIView *v = [self headerViewForSection:section];
    if (v) {
        CGSize s = [v systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        s.width = collectionView.frame.size.width;
        return s;
    }
    return CGSizeZero;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    id header = nil;
    if ([self.delegate respondsToSelector:_cmd]) {
        header = [(id<UICollectionViewDataSource>)self.delegate collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
    
    header = header ?: [self sectionAtIndex:indexPath.section].header;
    if ([header isKindOfClass:[UIView class]]) {
        return header;
    }
    else {
        NSString *sectionTitle = [[header description] uppercaseString];
        header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kind forIndexPath:indexPath];
        [header label].text = sectionTitle;
        return header;
    }
    
    return nil;
}

#pragma mark - Delegate
- (BOOL)collectionView:(__unused UICollectionView *)collectionView canPerformAction:(__unused SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(__unused id)sender {
    FXFormBaseView *v = [self formViewForField:[self fieldForIndexPath:indexPath]];
    return [v.field isCollectionType] || [v.field isOrderedCollectionType];
}

- (BOOL)collectionView:(__unused UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    FXFormBaseView *v = [self formViewForField:[self fieldForIndexPath:indexPath]];
    return [v.field isCollectionType] || [v.field isOrderedCollectionType];
}

- (void)collectionView:(__unused UICollectionView *)collectionView performAction:(__unused SEL)action forItemAtIndexPath:(__unused NSIndexPath *)indexPath withSender:(__unused id)sender {
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    FXFormCollectionCell *cell = (FXFormCollectionCell *)[self cellForRowAtIndexPath:indexPath];
    
    //forward to cell
    if ([cell.formView respondsToSelector:@selector(didSelectWithView:withViewController:withFormController:)]) {
        [cell.formView didSelectWithView:collectionView withViewController:[self viewController] withFormController:self];
    }
    
    //forward to delegate
    if ([self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [(id<UICollectionViewDelegate>)self.delegate collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

@end


@interface FXFormCollectionViewController ()
@property (nonatomic, strong) FXCollectionFormController *formController;
@end

@implementation FXFormCollectionViewController
@synthesize collectionView = _collectionView;
@synthesize field = _field;

- (void)dealloc {
    _formController.delegate = nil;
}

- (void)setField:(FXFormField *)field {
    _field = field;
    
    id<FXForm> form = nil;
    if (field.options) {
        form = [[FXOptionsForm alloc] initWithField:field];
    }
    else if ([field isCollectionType]) {
        form = [[FXTemplateForm alloc] initWithField:field];
    }
    else if ([field.valueClass conformsToProtocol:@protocol(FXForm)]) {
        if (!field.value && ![field.valueClass isSubclassOfClass:FXFormClassFromString(@"NSManagedObject")]) {
            //create a new instance of the form automatically
            field.value = [[field.valueClass alloc] init];
        }
        form = field.value;
    }
    else {
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
        l.minimumInteritemSpacing = 0.f;
        l.minimumLineSpacing = 0.f;
        l.sectionInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
        self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                                 collectionViewLayout:l];
        self.collectionView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
    if (!self.collectionView.superview) {
        self.view = self.collectionView;
    }
}

- (void)setCollectionView:(UICollectionView *)collectionView {
    _collectionView = collectionView;
    self.formController.collectionView = collectionView;
}

- (void)willRotateToInterfaceOrientation:(__unused UIInterfaceOrientation)toInterfaceOrientation duration:(__unused NSTimeInterval)duration {
    [self.collectionView.collectionViewLayout invalidateLayout];
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

