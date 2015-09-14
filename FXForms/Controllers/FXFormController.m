//
//  FXFormController.m
//  BasicExample
//
//  Created by Joseph Ridenour on 2/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormController.h"
#import "FXFormsDefines.h"
#import "FXFormField.h"
#import "FXFormModels.h"
#import "FXFormTableCells.h"
#import "FXFormController_Private.h"
#import "FXTableFormController.h"
#import "FXCollectionFormController.h"
#import "FXFormTableCells.h"

@implementation FXFormController

- (instancetype)init
{
    if ((self = [super init]))
    {
        _cellBackgroundColor = [UIColor whiteColor];
        _cellDividerColor = [UIColor lightGrayColor];
        _cellHeightCache = [NSMutableDictionary dictionary];
        _cellClassesForFieldTypes = [@{FXFormFieldTypeDefault: [FXFormDefaultCell class],
                                       FXFormFieldTypeText: [FXFormTextFieldCell class],
                                       FXFormFieldTypeLongText: [FXFormTextViewCell class],
                                       FXFormFieldTypeURL: [FXFormTextFieldCell class],
                                       FXFormFieldTypeEmail: [FXFormTextFieldCell class],
                                       FXFormFieldTypePhone: [FXFormTextFieldCell class],
                                       FXFormFieldTypePassword: [FXFormTextFieldCell class],
                                       FXFormFieldTypeNumber: [FXFormTextFieldCell class],
                                       FXFormFieldTypeFloat: [FXFormTextFieldCell class],
                                       FXFormFieldTypeInteger: [FXFormTextFieldCell class],
                                       FXFormFieldTypeUnsigned: [FXFormTextFieldCell class],
                                       FXFormFieldTypeBoolean: [FXFormSwitchCell class],
                                       FXFormFieldTypeDate: [FXFormDatePickerCell class],
                                       FXFormFieldTypeTime: [FXFormDatePickerCell class],
                                       FXFormFieldTypeDateTime: [FXFormDatePickerCell class],
                                       FXFormFieldTypeImage: [FXFormImagePickerCell class]} mutableCopy];
        _cellClassesForFieldClasses = [NSMutableDictionary dictionary];
        _controllerClassesForFieldTypes = [@{FXFormFieldTypeDefault: [FXFormTableViewController class]} mutableCopy];
        _controllerClassesForFieldClasses = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Cell Registrations
- (Class)cellClassForField:(FXFormField *)field {
    Class aClass = field.cellClass;
    if (!aClass) {
        if (field.type != FXFormFieldTypeDefault) {
            aClass = self.cellClassesForFieldTypes[field.type] ?:
            self.parentFormController.cellClassesForFieldTypes[field.type] ?:
            self.cellClassesForFieldTypes[FXFormFieldTypeDefault];
        }
        else {
            Class valueClass = field.valueClass;
            while (valueClass && valueClass != [NSObject class])
            {
                Class cellClass = self.cellClassesForFieldClasses[NSStringFromClass(valueClass)] ?:
                self.parentFormController.cellClassesForFieldClasses[NSStringFromClass(valueClass)];
                if (cellClass) {
                    return cellClass;
                }
                valueClass = [valueClass superclass];
            }
            aClass = self.cellClassesForFieldTypes[FXFormFieldTypeDefault];
        }
    }
    
    if ([self isKindOfClass:[FXTableFormController class]]) {
        // For now we want to ensure anything ending in "View" gets replaced with the "Cell" versions
        NSString *classString = NSStringFromClass(aClass);
        if (NSMaxRange([classString rangeOfString:@"View"]) == (classString.length)) {
            classString = [classString stringByReplacingCharactersInRange:NSMakeRange(classString.length-4, 4) withString:@"Cell"];
            aClass = NSClassFromString(classString);
        }
    }
    return aClass;
}

- (void)registerDefaultFieldCellClass:(Class)cellClass
{
    NSParameterAssert([cellClass conformsToProtocol:@protocol(FXFormFieldCell)]);
    [self.cellClassesForFieldTypes setDictionary:@{FXFormFieldTypeDefault: cellClass}];
}

- (void)registerCellClass:(Class)cellClass forFieldType:(NSString *)fieldType
{
    NSParameterAssert([cellClass conformsToProtocol:@protocol(FXFormFieldCell)]);
    self.cellClassesForFieldTypes[fieldType] = cellClass;
}

- (void)registerCellClass:(Class)cellClass forFieldClass:(__unsafe_unretained Class)fieldClass
{
    NSParameterAssert([cellClass conformsToProtocol:@protocol(FXFormFieldCell)]);
    self.cellClassesForFieldClasses[NSStringFromClass(fieldClass)] = cellClass;
}

- (Class)viewControllerClassForField:(FXFormField *)field
{
    if (field.type != FXFormFieldTypeDefault)
    {
        return self.controllerClassesForFieldTypes[field.type] ?:
        self.parentFormController.controllerClassesForFieldTypes[field.type] ?:
        self.controllerClassesForFieldTypes[FXFormFieldTypeDefault];
    }
    else
    {
        Class valueClass = field.valueClass;
        while (valueClass != [NSObject class])
        {
            Class controllerClass = self.controllerClassesForFieldClasses[NSStringFromClass(valueClass)] ?:
            self.parentFormController.controllerClassesForFieldClasses[NSStringFromClass(valueClass)];
            if (controllerClass)
            {
                return controllerClass;
            }
            valueClass = [valueClass superclass];
        }
        return self.controllerClassesForFieldTypes[FXFormFieldTypeDefault];
    }
}

- (void)registerDefaultViewControllerClass:(Class)controllerClass
{
    NSParameterAssert([controllerClass conformsToProtocol:@protocol(FXFormFieldViewController)]);
    [self.controllerClassesForFieldTypes setDictionary:@{FXFormFieldTypeDefault: controllerClass}];
}

- (void)registerViewControllerClass:(Class)controllerClass forFieldType:(NSString *)fieldType
{
    NSParameterAssert([controllerClass conformsToProtocol:@protocol(FXFormFieldViewController)]);
    self.controllerClassesForFieldTypes[fieldType] = controllerClass;
}

- (void)registerViewControllerClass:(Class)controllerClass forFieldClass:(__unsafe_unretained Class)fieldClass
{
    NSParameterAssert([controllerClass conformsToProtocol:@protocol(FXFormFieldViewController)]);
    self.controllerClassesForFieldClasses[NSStringFromClass(fieldClass)] = controllerClass;
}

#pragma mark - Setters
- (void)setForm:(id<FXForm>)form
{
    _form = form;
    self.sections = [FXFormSection sectionsWithForm:form controller:self];
}

#pragma mark - Getters
- (UICollectionView *)collectionView {
    return [self.scrollView isKindOfClass:[UICollectionView class]] ? (UICollectionView *)self.scrollView : nil;
}

- (UITableView *)tableView {
    return [self.scrollView isKindOfClass:[UITableView class]] ? (UITableView *)self.scrollView : nil;
}

- (UIViewController *)viewController {
    id responder = self.scrollView;
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

#pragma mark - Method Forwarding
- (BOOL)respondsToSelector:(SEL)selector
{
    return [super respondsToSelector:selector] || [self.delegate respondsToSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation invokeWithTarget:self.delegate];
}

#pragma mark - datasource
- (NSUInteger)numberOfSections
{
    return [self.sections count];
}

- (FXFormSection *)sectionAtIndex:(NSUInteger)index
{
    return self.sections[index];
}

- (NSUInteger)numberOfFieldsInSection:(NSUInteger)index
{
    return [[self sectionAtIndex:index].fields count];
}

- (FXFormField *)fieldForKey:(NSString *)key {
    __block FXFormField *foundField = nil;
    [self enumerateFieldsWithBlock:^(FXFormField *field, __unused NSIndexPath *indexPath) {
        if (foundField) return;
        
        if ([field.key isEqualToString:key]) {
            foundField = field;
        }
    }];
    return foundField;
}

- (FXFormField *)fieldForIndexPath:(NSIndexPath *)indexPath
{
    return [self sectionAtIndex:indexPath.section].fields[indexPath.row];
}

- (NSIndexPath *)indexPathForField:(FXFormField *)field
{
    NSUInteger sectionIndex = 0;
    for (FXFormSection *section in self.sections)
    {
        NSUInteger fieldIndex = [section.fields indexOfObject:field];
        if (fieldIndex != NSNotFound)
        {
            return [NSIndexPath indexPathForRow:fieldIndex inSection:sectionIndex];
        }
        sectionIndex ++;
    }
    return nil;
}

- (NSIndexPath *)indexPathForNextResponderCellAfterCell:(id<FXFormFieldCell>)cell {
    
    __block NSIndexPath *indexPath = nil;
    [self performUIChange:^(UITableView *tableView) {
        indexPath = [tableView indexPathForCell:(UITableViewCell *)cell];
    } collection:^(UICollectionView *collectionView) {
        indexPath = [collectionView indexPathForCell:(UICollectionViewCell *)cell];
    }];
    
    if (indexPath) {
        if ([self numberOfFieldsInSection:indexPath.section] > (NSUInteger)(indexPath.item + 1)) {
            NSIndexPath *ip = [NSIndexPath indexPathForItem:indexPath.item + 1 inSection:indexPath.section];
            FXFormBaseCell *nextCell = (FXFormBaseCell *)[self cellForRowAtIndexPath:ip];

            // Must skip over fields that cannot becomeFirstResponder
            if (![nextCell canBecomeFirstResponder]) {
                ip = [self indexPathForNextResponderCellAfterCell:nextCell];
            }
            
            return ip;
        }
        else if([self numberOfSections] > (NSUInteger)(indexPath.section + 1)) {
            return [NSIndexPath indexPathForItem:0 inSection:indexPath.section + 1];
        }
    }
    
    return nil;
}

- (NSIndexPath *)indexPathForNextCellAfterCell:(id<FXFormFieldCell>)cell {
    __block NSIndexPath *indexPath = nil;
    [self performUIChange:^(UITableView *tableView) {
        indexPath = [tableView indexPathForCell:(UITableViewCell *)cell];
    } collection:^(UICollectionView *collectionView) {
        indexPath = [collectionView indexPathForCell:(UICollectionViewCell *)cell];
    }];
    
    if (indexPath) {
        
        if ([self numberOfFieldsInSection:indexPath.section] > (NSUInteger)(indexPath.item + 1)) {
            return [NSIndexPath indexPathForItem:indexPath.item + 1 inSection:indexPath.section];
        }
        else if([self numberOfSections] > (NSUInteger)(indexPath.section + 1)) {
            return [NSIndexPath indexPathForItem:0 inSection:indexPath.section + 1];
        }
    }
    
    return nil;
}

- (NSIndexPath *)indexPathForPreviousResponderCellBeforeCell:(id<FXFormFieldCell>)cell {
    __block NSIndexPath *indexPath = nil;
    [self performUIChange:^(UITableView *tableView) {
        indexPath = [tableView indexPathForCell:(UITableViewCell *)cell];
    } collection:^(UICollectionView *collectionView) {
        indexPath = [collectionView indexPathForCell:(UICollectionViewCell *)cell];
    }];
    
    if (indexPath) {
        if ([self numberOfFieldsInSection:indexPath.section] > (NSUInteger)(indexPath.item - 1) && indexPath.item > 0) {
            NSIndexPath *ip = [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section];
            FXFormBaseCell *beforeCell = (FXFormBaseCell *)[self cellForRowAtIndexPath:ip];
            
            // Must skip over fields that cannot becomeFirstResponder
            if (![beforeCell canBecomeFirstResponder]) {
                ip = [self indexPathForPreviousResponderCellBeforeCell:beforeCell];
            }
            
            return ip;
        }
        else if([self numberOfSections] > (NSUInteger)(indexPath.section) && indexPath.section > 0) {
            return [NSIndexPath indexPathForItem:0 inSection:indexPath.section - 1];
        }
    }
    
    return nil;
}

- (NSIndexPath *)indexPathForPreviousCellBeforeCell:(id<FXFormFieldCell>)cell {
    __block NSIndexPath *indexPath = nil;
    [self performUIChange:^(UITableView *tableView) {
        indexPath = [tableView indexPathForCell:(UITableViewCell *)cell];
    } collection:^(UICollectionView *collectionView) {
        indexPath = [collectionView indexPathForCell:(UICollectionViewCell *)cell];
    }];
    
    if (indexPath) {
        if ([self numberOfFieldsInSection:indexPath.section] > (NSUInteger)(indexPath.item - 1)) {
            return [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section];
        }
        else if([self numberOfSections] > (NSUInteger)(indexPath.section)) {
            return [NSIndexPath indexPathForItem:0 inSection:indexPath.section - 1];
        }
    }
    
    return nil;
}

- (id <FXFormFieldCell>)cellForField:(FXFormField *)field
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
        //hackity-hack-hack
        UITableViewCellStyle style = UITableViewCellStyleDefault;
        if ([field valueForKeyPath:@"style"])
        {
            style = [[field valueForKeyPath:@"style"] integerValue];
        }
        else if (FXFormCanGetValueForKey(field.form, field.key))
        {
            style = UITableViewCellStyleValue1;
        }
        
        //don't recycle cells - it would make things complicated
        return [[cellClass alloc] initWithStyle:style reuseIdentifier:NSStringFromClass(cellClass)];
    }
}

- (id<FXFormFieldCell>)cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // This is acceptable since the performUIChange method isn't asynchronous
    __block id cell = nil;
    [self performUIChange:^(UITableView *tableView) {
        cell = (id<FXFormFieldCell>)[tableView cellForRowAtIndexPath:indexPath];
    } collection:^(UICollectionView *collectionView) {
        cell = [collectionView cellForItemAtIndexPath:indexPath];
    }];
    return cell;
}

- (id<FXFormFieldCell>)nextResponderCellForCell:(id<FXFormFieldCell>)cell {
    NSIndexPath *nextIndexPath = [self indexPathForNextResponderCellAfterCell:cell];
    if (nextIndexPath) {
        return [self cellForRowAtIndexPath:nextIndexPath];
    }
    
    return nil;
}

- (id<FXFormFieldCell>)nextCellForCell:(id<FXFormFieldCell>)cell {
    NSIndexPath *nextIndexPath = [self indexPathForNextCellAfterCell:cell];
    if (nextIndexPath) {
        return [self cellForRowAtIndexPath:nextIndexPath];
    }
    
    return nil;
}

- (id<FXFormFieldCell>)previousResponderCellForCell:(id<FXFormFieldCell>)cell {
    NSIndexPath *prevIndexPath = [self indexPathForPreviousResponderCellBeforeCell:cell];
    if (prevIndexPath) {
        return [self cellForRowAtIndexPath:prevIndexPath];
    }
    
    return nil;
}

- (id<FXFormFieldCell>)previousCellForCell:(id<FXFormFieldCell>)cell {
    NSIndexPath *prevIndexPath = [self indexPathForPreviousCellBeforeCell:cell];
    if (prevIndexPath) {
        return [self cellForRowAtIndexPath:prevIndexPath];
    }
    
    return nil;
}

- (id<FXFormFieldCell>)nextCell {
    return [self nextResponderCellForCell:self.currentResponderCell];
}

- (id<FXFormFieldCell>)previousCell {
    return [self previousResponderCellForCell:self.currentResponderCell];
}

#pragma mark - Actions
- (void)performUIChange:(void(^)(UITableView *tableView))tableViewBlock collection:(void(^)(UICollectionView *collectionView))collectionViewBlock {
    if ([self tableView]) {
        tableViewBlock([self tableView]);
    } else if ([self collectionView]) {
        collectionViewBlock([self collectionView]);
    }
}

- (void)performUpdates:(void(^)())updatesBlock withCompletion:(void(^)())completion {
    [self performUIChange:^(UITableView *tableView) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:completion];
        [tableView beginUpdates];
        if (updatesBlock) {
            updatesBlock();
        }
        [tableView endUpdates];
        [CATransaction commit];
    } collection:^(UICollectionView *collectionView) {
        [collectionView performBatchUpdates:updatesBlock completion:^(__unused BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void)deselectRowAtIndexPath:(NSIndexPath *)ip animated:(BOOL)animated {
    __block NSIndexPath *indexPath = ip;
    [self performUIChange:^(UITableView *tableView) {
        indexPath = indexPath ?: [tableView indexPathForSelectedRow];
        [tableView deselectRowAtIndexPath:indexPath animated:animated];
    } collection:^(UICollectionView *collectionView) {
        indexPath = indexPath ?: [[collectionView indexPathsForSelectedItems] firstObject];
        [collectionView deselectItemAtIndexPath:indexPath animated:animated];
    }];
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition {
    [self performUIChange:^(UITableView *tableView) {
        [tableView selectRowAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition];
    } collection:^(UICollectionView *collectionView) {
        [collectionView selectItemAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition];
    }];
}

- (void)didSelectRowAtIndexPath:(__unused NSIndexPath *)indexPath {
    
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths {
    [self performUIChange:^(UITableView *tableView) {
        [tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } collection:^(UICollectionView *collectionView) {
        [collectionView insertItemsAtIndexPaths:indexPaths];
    }];
}

- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths {
    [self performUIChange:^(UITableView *tableView) {
        [tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } collection:^(UICollectionView *collectionView) {
        [collectionView deleteItemsAtIndexPaths:indexPaths];
    }];
}

- (void)refreshRowsInSections:(NSIndexSet *)indexSet {
    [self performUIChange:^(UITableView *tableView) {
        [tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    } collection:^(UICollectionView *collectionView) {
        [collectionView reloadSections:indexSet];
    }];
}

- (void)enumerateFieldsWithBlock:(void (^)(FXFormField *field, NSIndexPath *indexPath))block {
    NSUInteger sectionIndex = 0;
    for (FXFormSection *section in self.sections)
    {
        NSUInteger fieldIndex = 0;
        for (FXFormField *field in section.fields)
        {
            block(field, [NSIndexPath indexPathForRow:fieldIndex inSection:sectionIndex]);
            fieldIndex ++;
        }
        sectionIndex ++;
    }
}

#pragma mark -
#pragma mark Action handler

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)performAction:(SEL)selector withSender:(id)sender {
    // First check if the form itself responds to this selector
    BOOL (^Responds)(id target) = ^(id target) {
        if ([target respondsToSelector:selector]) {
            [target performSelector:selector withObject:sender];
            return YES;
        }
        return NO;
    };
    
    // First check the form
    if (Responds(self.form)) { return; }
    
    //walk up responder chain
    id responder = self.scrollView;
    while (responder) {
        if (Responds(responder)) {
            return;
        }
        responder = [responder nextResponder];
    }
    
    //trye parent controller
    if (self.parentFormController) {
        [self.parentFormController performAction:selector withSender:sender];
    }
    else {
        [NSException raise:FXFormsException format:@"No object in the responder chain responds to the selector %@", NSStringFromSelector(selector)];
    }
}
#pragma clang diagnostic pop

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //dismiss keyboard
    [FXFormsFirstResponder(self.scrollView) resignFirstResponder];
    
    //forward to delegate
    if ([self.delegate respondsToSelector:_cmd])
    {
        [(id<UIScrollViewDelegate>)self.delegate scrollViewWillBeginDragging:scrollView];
    }
}

#pragma mark -
#pragma mark Keyboard events

- (id<FXFormFieldCell>)cellContainingView:(UIView *)view {
    
    if (view == nil || [view isKindOfClass:[FXFormBaseView class]]) {
        return (id<FXFormFieldCell>)view;
    }
    return [self cellContainingView:view.superview];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    id <FXFormFieldCell> cell = [self cellContainingView:FXFormsFirstResponder(self.scrollView)];
    if (cell && ![self.delegate isKindOfClass:[UITableViewController class]])
    {
        NSDictionary *keyboardInfo = [note userInfo];
        CGRect keyboardFrame = [keyboardInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        keyboardFrame = [self.scrollView.window convertRect:keyboardFrame toView:self.scrollView.superview];
        CGFloat inset = self.scrollView.frame.origin.y + self.scrollView.frame.size.height - keyboardFrame.origin.y;
        
        UIEdgeInsets tableContentInset = self.scrollView.contentInset;
        tableContentInset.bottom = inset;
        
        UIEdgeInsets tableScrollIndicatorInsets = self.scrollView.scrollIndicatorInsets;
        tableScrollIndicatorInsets.bottom = inset;
        
        //animate insets
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:(UIViewAnimationCurve)keyboardInfo[UIKeyboardAnimationCurveUserInfoKey]];
        [UIView setAnimationDuration:[keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        NSIndexPath *indexPath = [self indexPathForField:cell.field];
        [self performUIChange:^(UITableView *tableView) {
            self.scrollView.contentInset = tableContentInset;
            self.scrollView.scrollIndicatorInsets = tableScrollIndicatorInsets;
            [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        } collection:^(UICollectionView *collectionView) {
            [collectionView.collectionViewLayout invalidateLayout];
            self.scrollView.contentInset = tableContentInset;
            self.scrollView.scrollIndicatorInsets = tableScrollIndicatorInsets;
            [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        }];
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHide:(NSNotification *)note
{
    id <FXFormFieldCell> cell = [self cellContainingView:FXFormsFirstResponder(self.scrollView)];
    if (cell && ![self.delegate isKindOfClass:[UITableViewController class]])
    {
        NSDictionary *keyboardInfo = [note userInfo];
        
        UIEdgeInsets tableContentInset = self.scrollView.contentInset;
        tableContentInset.bottom = 0;
        
        UIEdgeInsets tableScrollIndicatorInsets = self.scrollView.scrollIndicatorInsets;
        tableScrollIndicatorInsets.bottom = 0;
        
        //restore insets
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:(UIViewAnimationCurve)keyboardInfo[UIKeyboardAnimationCurveUserInfoKey]];
        [UIView setAnimationDuration:[keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        self.scrollView.contentInset = tableContentInset;
        self.scrollView.scrollIndicatorInsets = tableScrollIndicatorInsets;
        [UIView commitAnimations];
    }
}

@end
