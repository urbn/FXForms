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

#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma clang diagnostic ignored "-Wreceiver-is-weak"
#pragma clang diagnostic ignored "-Wconversion"
#pragma clang diagnostic ignored "-Wgnu"

@interface FXFormController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *cellHeightCache;
@property (nonatomic, strong) NSMutableDictionary *cellClassesForFieldTypes;
@property (nonatomic, strong) NSMutableDictionary *cellClassesForFieldClasses;
@property (nonatomic, strong) NSMutableDictionary *controllerClassesForFieldTypes;
@property (nonatomic, strong) NSMutableDictionary *controllerClassesForFieldClasses;


- (UIViewController *)tableViewController;

@end


@implementation FXFormController

- (instancetype)init
{
    if ((self = [super init]))
    {
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
        _controllerClassesForFieldTypes = [@{FXFormFieldTypeDefault: [FXFormViewController class]} mutableCopy];
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
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (Class)cellClassForField:(FXFormField *)field
{
    if (field.type != FXFormFieldTypeDefault)
    {
        return self.cellClassesForFieldTypes[field.type] ?:
        self.parentFormController.cellClassesForFieldTypes[field.type] ?:
        self.cellClassesForFieldTypes[FXFormFieldTypeDefault];
    }
    else
    {
        Class valueClass = field.valueClass;
        while (valueClass && valueClass != [NSObject class])
        {
            Class cellClass = self.cellClassesForFieldClasses[NSStringFromClass(valueClass)] ?:
            self.parentFormController.cellClassesForFieldClasses[NSStringFromClass(valueClass)];
            if (cellClass)
            {
                return cellClass;
            }
            valueClass = [valueClass superclass];
        }
        return self.cellClassesForFieldTypes[FXFormFieldTypeDefault];
    }
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

- (void)setDelegate:(id<FXFormControllerDelegate>)delegate
{
    _delegate = delegate;
    
    //force table to update respondsToSelector: cache
    self.tableView.delegate = nil;
    self.tableView.delegate = self;
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return [super respondsToSelector:selector] || [self.delegate respondsToSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation invokeWithTarget:self.delegate];
}

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.editing = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
    [self.tableView reloadData];
}

- (UIViewController *)tableViewController
{
    id responder = self.tableView;
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

- (void)setForm:(id<FXForm>)form
{
    _form = form;
    self.sections = [FXFormSection sectionsWithForm:form controller:self];
}

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

- (void)enumerateFieldsWithBlock:(void (^)(FXFormField *field, NSIndexPath *indexPath))block
{
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

- (void)performAction:(SEL)selector withSender:(id)sender
{
    //walk up responder chain
    id responder = self.tableView;
    while (responder)
    {
        if ([responder respondsToSelector:selector])
        {
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            
            [responder performSelector:selector withObject:sender];
            
#pragma clang diagnostic pop
            
            return;
        }
        responder = [responder nextResponder];
    }
    
    //trye parent controller
    if (self.parentFormController)
    {
        [self.parentFormController performAction:selector withSender:sender];
    }
    else
    {
        [NSException raise:FXFormsException format:@"No object in the responder chain responds to the selector %@", NSStringFromSelector(selector)];
    }
}

#pragma mark -
#pragma mark Datasource methods

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView
{
    return [self numberOfSections];
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForHeaderInSection:(NSInteger)index
{
    return [[self sectionAtIndex:index].header description];
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForFooterInSection:(NSInteger)index
{
    return [[self sectionAtIndex:index].footer description];
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)index
{
    return [self numberOfFieldsInSection:index];
}

- (UITableViewCell *)cellForField:(FXFormField *)field
{
    //don't recycle cells - it would make things complicated
    Class cellClass = field.cellClass ?: [self cellClassForField:field];
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

- (CGFloat)tableView:(__unused UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FXFormField *field = [self fieldForIndexPath:indexPath];
    Class cellClass = field.cellClass ?: [self cellClassForField:field];
    if ([cellClass respondsToSelector:@selector(heightForField:width:)])
    {
        return [cellClass heightForField:field width:self.tableView.frame.size.width];
    }
    
    NSString *className = NSStringFromClass(cellClass);
    NSNumber *cachedHeight = _cellHeightCache[className];
    if (!cachedHeight)
    {
        UITableViewCell *cell = [self cellForField:field];
        cachedHeight = @(cell.bounds.size.height);
        _cellHeightCache[className] = cachedHeight;
    }
    
    return [cachedHeight floatValue];
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellForField:[self fieldForIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [tableView beginUpdates];
        
        FXFormSection *section = [self sectionAtIndex:indexPath.section];
        [section removeFieldAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [tableView endUpdates];
    }
}

- (void)tableView:(__unused UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    FXFormSection *section = [self sectionAtIndex:sourceIndexPath.section];
    [section moveFieldAtIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
}

- (NSIndexPath *)tableView:(__unused UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    FXFormSection *section = [self sectionAtIndex:sourceIndexPath.section];
    if (sourceIndexPath.section == proposedDestinationIndexPath.section &&
        proposedDestinationIndexPath.row < (NSInteger)[section.fields count] - 1)
    {
        return proposedDestinationIndexPath;
    }
    return sourceIndexPath;
}

- (BOOL)tableView:(__unused UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    FXFormSection *section = [self sectionAtIndex:indexPath.section];
    if ([section.form isKindOfClass:[FXTemplateForm class]])
    {
        if (indexPath.row < (NSInteger)[section.fields count] - 1)
        {
            FXFormField *field = ((FXTemplateForm *)section.form).field;
            return [field isOrderedCollectionType] && field.isSortable;
        }
    }
    return NO;
}

#pragma mark -
#pragma mark Delegate methods

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)index
{
    //forward to delegate
    if ([self.delegate respondsToSelector:_cmd])
    {
        return [self.delegate tableView:tableView viewForHeaderInSection:index];
    }
    
    //handle view or class
    id header = [self sectionAtIndex:index].header;
    if ([header isKindOfClass:[UIView class]])
    {
        return header;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)index
{
    //forward to delegate
    if ([self.delegate respondsToSelector:_cmd])
    {
        return [self.delegate tableView:tableView heightForHeaderInSection:index];
    }
    
    //handle view or class
    UIView *header = [self sectionAtIndex:index].header;
    if ([header isKindOfClass:[UIView class]])
    {
        return header.frame.size.height ?: UITableViewAutomaticDimension;
    }
    return UITableViewAutomaticDimension;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)index
{
    //forward to delegate
    if ([self.delegate respondsToSelector:_cmd])
    {
        return [self.delegate tableView:tableView viewForFooterInSection:index];
    }
    
    //handle view or class
    id footer = [self sectionAtIndex:index].footer;
    if ([footer isKindOfClass:[UIView class]])
    {
        return footer;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)index
{
    //forward to delegate
    if ([self.delegate respondsToSelector:_cmd])
    {
        return [self.delegate tableView:tableView heightForFooterInSection:index];
    }
    
    //handle view or class
    UIView *footer = [self sectionAtIndex:index].footer;
    if ([footer isKindOfClass:[UIView class]])
    {
        return footer.frame.size.height ?: UITableViewAutomaticDimension;
    }
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    FXFormField *field = [self fieldForIndexPath:indexPath];
    
    //configure cell before setting field (in case it affects how value is displayed)
    [field.cellConfig enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, id value, __unused BOOL *stop) {
        [cell setValue:value forKeyPath:keyPath];
    }];
    
    //set form field
    ((id<FXFormFieldCell>)cell).field = field;
    
    //configure cell after setting field as well (not ideal, but allows overriding keyboard attributes, etc)
    [field.cellConfig enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, id value, __unused BOOL *stop) {
        [cell setValue:value forKeyPath:keyPath];
    }];
    
    //forward to delegate
    if ([self.delegate respondsToSelector:_cmd])
    {
        [self.delegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //forward to cell
    UITableViewCell<FXFormFieldCell> *cell = (UITableViewCell<FXFormFieldCell> *)[tableView cellForRowAtIndexPath:indexPath];
    if ([cell respondsToSelector:@selector(didSelectWithTableView:controller:)])
    {
        [cell didSelectWithTableView:tableView controller:[self tableViewController]];
    }
    
    //forward to delegate
    if ([self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
    {
        [self.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (UITableViewCellEditingStyle)tableView:(__unused UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FXFormSection *section = [self sectionAtIndex:indexPath.section];
    if ([section.form isKindOfClass:[FXTemplateForm class]])
    {
        if (indexPath.row == (NSInteger)[section.fields count] - 1)
        {
            return UITableViewCellEditingStyleInsert;
        }
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(__unused UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(__unused NSIndexPath *)indexPath
{
    return NO;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //dismiss keyboard
    [FXFormsFirstResponder(self.tableView) resignFirstResponder];
    
    //forward to delegate
    if ([self.delegate respondsToSelector:_cmd])
    {
        [self.delegate scrollViewWillBeginDragging:scrollView];
    }
}

#pragma mark -
#pragma mark Keyboard events

- (UITableViewCell *)cellContainingView:(UIView *)view
{
    if (view == nil || [view isKindOfClass:[UITableViewCell class]])
    {
        return (UITableViewCell *)view;
    }
    return [self cellContainingView:view.superview];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    UITableViewCell *cell = [self cellContainingView:FXFormsFirstResponder(self.tableView)];
    if (cell && ![self.delegate isKindOfClass:[UITableViewController class]])
    {
        NSDictionary *keyboardInfo = [note userInfo];
        CGRect keyboardFrame = [keyboardInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        keyboardFrame = [self.tableView.window convertRect:keyboardFrame toView:self.tableView.superview];
        CGFloat inset = self.tableView.frame.origin.y + self.tableView.frame.size.height - keyboardFrame.origin.y;
        
        UIEdgeInsets tableContentInset = self.tableView.contentInset;
        tableContentInset.bottom = inset;
        
        UIEdgeInsets tableScrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
        tableScrollIndicatorInsets.bottom = inset;
        
        //animate insets
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:(UIViewAnimationCurve)keyboardInfo[UIKeyboardAnimationCurveUserInfoKey]];
        [UIView setAnimationDuration:[keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        self.tableView.contentInset = tableContentInset;
        self.tableView.scrollIndicatorInsets = tableScrollIndicatorInsets;
        NSIndexPath *selectedRow = [self.tableView indexPathForCell:cell];
        [self.tableView scrollToRowAtIndexPath:selectedRow atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHide:(NSNotification *)note
{
    UITableViewCell *cell = [self cellContainingView:FXFormsFirstResponder(self.tableView)];
    if (cell && ![self.delegate isKindOfClass:[UITableViewController class]])
    {
        NSDictionary *keyboardInfo = [note userInfo];
        
        UIEdgeInsets tableContentInset = self.tableView.contentInset;
        tableContentInset.bottom = 0;
        
        UIEdgeInsets tableScrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
        tableScrollIndicatorInsets.bottom = 0;
        
        //restore insets
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:(UIViewAnimationCurve)keyboardInfo[UIKeyboardAnimationCurveUserInfoKey]];
        [UIView setAnimationDuration:[keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        self.tableView.contentInset = tableContentInset;
        self.tableView.scrollIndicatorInsets = tableScrollIndicatorInsets;
        [UIView commitAnimations];
    }
}

@end



@interface FXFormViewController ()

@property (nonatomic, strong) FXFormController *formController;

@end


@implementation FXFormViewController
@synthesize tableView = _tableView;
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

- (FXFormController *)formController
{
    if (!_formController)
    {
        _formController = [[FXFormController alloc] init];
        _formController.delegate = self;
    }
    return _formController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.tableView)
    {
        self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                      style:UITableViewStyleGrouped];
    }
    if (!self.tableView.superview)
    {
        self.view = self.tableView;
    }
}

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    self.formController.tableView = tableView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
    if (selected)
    {
        [self.tableView reloadData];
        [self.tableView selectRowAtIndexPath:selected animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self.tableView deselectRowAtIndexPath:selected animated:YES];
    }
}

@end

