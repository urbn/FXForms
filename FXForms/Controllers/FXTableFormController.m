//
//  FXTableFormController.m
//  BasicExample
//
//  Created by Joseph Ridenour on 2/20/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXTableFormController.h"
#import "FXFormsProtocols.h"
#import "FXFormsDefines.h"
#import "FXFormController_Private.h"
#import "FXFormField.h"
#import "FXFormModels.h"

@implementation FXTableFormController

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    self.scrollView = tableView;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.editing = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
    [self.tableView reloadData];
}

- (void)setDelegate:(id<FXFormControllerDelegate>)delegate {
    [super setDelegate:delegate];
    
    //force table to update respondsToSelector: cache
    self.tableView.delegate = nil;
    self.tableView.delegate = self;
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

- (void)dealloc {
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
}

#pragma mark - Datasource methods
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

- (CGFloat)tableView:(__unused UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FXFormField *field = [self fieldForIndexPath:indexPath];
    Class cellClass = field.cellClass ?: [self cellClassForField:field];
    if ([cellClass respondsToSelector:@selector(heightForField:width:)])
    {
        return [cellClass heightForField:field width:self.tableView.frame.size.width];
    }
    
    NSString *className = NSStringFromClass(cellClass);
    NSNumber *cachedHeight = self.cellHeightCache[className];
    if (!cachedHeight)
    {
        UITableViewCell *cell = (UITableViewCell *)[self cellForField:field];
        cachedHeight = @(cell.bounds.size.height);
        self.cellHeightCache[className] = cachedHeight;
    }
    
    return [cachedHeight floatValue];
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (UITableViewCell *)[self cellForField:[self fieldForIndexPath:indexPath]];
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

#pragma mark - Delegate methods
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

@end



@interface FXFormTableViewController ()

@property (nonatomic, strong) FXTableFormController *formController;

@end


@implementation FXFormTableViewController
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

- (FXTableFormController *)formController
{
    if (!_formController)
    {
        _formController = [[FXTableFormController alloc] init];
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

