//
//  FXFormModels.m
//  BasicExample
//
//  Created by Joseph Ridenour on 2/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormModels.h"
#import "FXFormField.h"
#import "FXFormController.h"
#import "FXFormsDefines.h"
#import "FXFormTableCells.h"
#import "FXFormModels.h"


#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma clang diagnostic ignored "-Wreceiver-is-weak"
#pragma clang diagnostic ignored "-Wconversion"
#pragma clang diagnostic ignored "-Wgnu"




@implementation FXOptionsForm

- (instancetype)initWithField:(FXFormField *)field
{
    if ((self = [super init]))
    {
        _field = field;
        id action = ^(__unused id sender)
        {
            if (field.action)
            {
                //this nasty hack is necessary to pass the expected cell as the sender
                FXFormController *formController = field.formController;
                [formController enumerateFieldsWithBlock:^(FXFormField *f, NSIndexPath *indexPath) {
                    if ([f.key isEqual:field.key])
                    {
                        field.action([formController cellForRowAtIndexPath:indexPath]);
                    }
                }];
            }
        };
        NSMutableArray *fields = [NSMutableArray array];
        if (field.placeholder)
        {
            [fields addObject:@{FXFormFieldKey: @"0",
                                FXFormFieldTitle: [field.placeholder fieldDescription],
                                FXFormFieldType: FXFormFieldTypeOption,
                                FXFormFieldAction: action}];
        }
        for (NSUInteger i = 0; i < [field.options count]; i++)
        {
            NSInteger index = i + (field.placeholder? 1: 0);
            [fields addObject:@{FXFormFieldKey: [@(index) description],
                                FXFormFieldTitle: [field optionDescriptionAtIndex:index],
                                FXFormFieldType: FXFormFieldTypeOption,
                                FXFormFieldAction: action}];
        }
        _fields = fields;
    }
    return self;
}

- (id)valueForKey:(NSString *)key
{
    NSInteger index = [key integerValue];
    return @([self.field isOptionSelectedAtIndex:index]);
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    NSUInteger index = [key integerValue];
    [self.field setOptionSelected:[value boolValue] atIndex:index];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    if ([NSStringFromSelector(selector) hasPrefix:@"set"])
    {
        return YES;
    }
    return [super respondsToSelector:selector];
}

@end



@implementation FXTemplateForm

- (instancetype)initWithField:(FXFormField *)field
{
    if ((self = [super init]))
    {
        _field = field;
        _fields = [NSMutableArray array];
        _values = [NSMutableArray array];
        [self updateFields];
    }
    return self;
}

- (NSMutableDictionary *)newFieldDictionary
{
    //TODO: is there a better way to handle default template fallback?
    //TODO: can we infer default template from existing values instead of having string fallback?
    NSMutableDictionary *field = [NSMutableDictionary dictionaryWithDictionary:self.field.fieldTemplate];
    FXFormPreprocessFieldDictionary(field);
    field[FXFormFieldTitle] = @""; // title is used for the "Add Item" button, not each field
    return field;
}

- (void)updateFields
{
    //set fields
    [self.fields removeAllObjects];
    NSUInteger count = [(NSArray *)self.field.value count];
    for (NSUInteger i = 0; i < count; i++)
    {
        //TODO: do we need to do something special with the action to ensure the
        //correct cell is passed as the sender, as we do for options fields?
        NSMutableDictionary *field = [self newFieldDictionary];
        field[FXFormFieldKey] = [@(i) description];
        [_fields addObject:field];
    }
    
    //create add button
    NSString *addButtonTitle = self.field.fieldTemplate[FXFormFieldTitle] ?: NSLocalizedString(@"Add Item", nil);
    [_fields addObject:@{FXFormFieldTitle: addButtonTitle,
                         FXFormFieldCell: [FXFormDefaultCell class],
                         @"textLabel.textAlignment": @(NSTextAlignmentLeft),
                         FXFormFieldAction: ^(UITableViewCell<FXFormFieldCell> *cell) {
        
        FXFormField *field = cell.field;
        FXFormController *formController = field.formController;
        
        NSIndexPath *indexPath = [formController indexPathForField:cell.field];
        FXFormSection *section = formController.sections[indexPath.section];
        
        [formController performUpdates:^{
            [section addNewField];
            [formController deselectRowAtIndexPath:indexPath animated:YES];
            [formController insertRowsAtIndexPaths:@[indexPath]];
        } withCompletion:^{
            [formController didSelectRowAtIndexPath:indexPath];
            [formController selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }];
    }}];
    
    //converts values to an ordered array
    if ([self.field.valueClass isSubclassOfClass:[NSIndexSet class]])
    {
        [self.fields removeAllObjects];
        [(NSIndexSet *)self.field.value enumerateIndexesUsingBlock:^(NSUInteger idx, __unused BOOL *stop) {
            [self.fields addObject:@(idx)];
        }];
    }
    else if ([self.field.valueClass isSubclassOfClass:[NSArray class]])
    {
        [self.values setArray:self.field.value];
    }
    else
    {
        [self.values setArray:[self.field.value allValues]];
    }
}

- (void)updateFormValue
{
    //create collection of correct type
    BOOL copyNeeded = ([NSStringFromClass(self.field.valueClass) rangeOfString:@"Mutable"].location == NSNotFound);
    id collection = [[self.field.valueClass alloc] init];
    if (copyNeeded) collection = [collection mutableCopy];
    
    //convert values back to original type
    if ([self.field.valueClass isSubclassOfClass:[NSIndexSet class]])
    {
        for (id object in self.values)
        {
            [collection addIndex:[object integerValue]];
        }
    }
    else if ([self.field.valueClass isSubclassOfClass:[NSDictionary class]])
    {
        [self.values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, __unused BOOL *stop) {
            collection[@(idx)] = obj;
        }];
    }
    else
    {
        [collection addObjectsFromArray:self.values];
    }
    
    //set field value
    if (copyNeeded) collection = [collection copy];
    self.field.value = collection;
}

- (id)valueForKey:(NSString *)key
{
    NSUInteger index = [key integerValue];
    if (index != NSNotFound)
    {
        id value = self.values[index];
        if (value != [NSNull null])
        {
            return value;
        }
    }
    return nil;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    //set value
    if (!value) value = [NSNull null];
    NSUInteger index = [key integerValue];
    if (index >= [self.values count])
    {
        [self.values addObject:value];
    }
    else
    {
        self.values[index] = value;
    }
    [self updateFormValue];
}

- (void)addNewField
{
    NSUInteger index = [self.values count];
    NSMutableDictionary *field = [self newFieldDictionary];
    field[FXFormFieldKey] = [@(index) description];
    [self.fields insertObject:field atIndex:index];
    [self.values addObject:[NSNull null]];
}

- (void)removeFieldAtIndex:(NSUInteger)index
{
    [self.fields removeObjectAtIndex:index];
    [self.values removeObjectAtIndex:index];
    for (NSUInteger i = index; i < [self.values count]; i++)
    {
        self.fields[index][FXFormFieldKey] = [@(i) description];
    }
    [self updateFormValue];
}

- (void)moveFieldAtIndex:(NSUInteger)index1 toIndex:(NSUInteger)index2
{
    NSMutableDictionary *field = self.fields[index1];
    [self.fields removeObjectAtIndex:index1];
    
    id value = self.values[index1];
    [self.values removeObjectAtIndex:index1];
    
    if (index2 >= [self.fields count])
    {
        [self.fields addObject:field];
        [self.values addObject:value];
    }
    else
    {
        [self.fields insertObject:field atIndex:index2];
        [self.values insertObject:value atIndex:index2];
    }
    
    for (NSUInteger i = MIN(index1, index2); i < [self.values count]; i++)
    {
        self.fields[i][FXFormFieldKey] = [@(i) description];
    }
    
    [self updateFormValue];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    if ([NSStringFromSelector(selector) hasPrefix:@"set"])
    {
        return YES;
    }
    return [super respondsToSelector:selector];
}

@end


@implementation FXFormSection

+ (NSArray *)sectionsWithForm:(id<FXForm>)form controller:(FXFormController *)formController
{
    NSMutableArray *sections = [NSMutableArray array];
    FXFormSection *section = nil;
    for (FXFormField *field in [FXFormField fieldsWithForm:form controller:formController])
    {
        id<FXForm> subform = nil;
        if (field.options && field.isInline)
        {
            subform = [[FXOptionsForm alloc] initWithField:field];
        }
        else if ([field isCollectionType] && field.isInline)
        {
            subform = [[FXTemplateForm alloc] initWithField:field];
        }
        else if ([field.valueClass conformsToProtocol:@protocol(FXForm)] && field.isInline)
        {
            if (!field.value && [field respondsToSelector:@selector(init)] &&
                ![field.valueClass isSubclassOfClass:FXFormClassFromString(@"NSManagedObject")])
            {
                //create a new instance of the form automatically
                field.value = [[field.valueClass alloc] init];
            }
            subform = field.value;
        }
        
        if (subform)
        {
            NSArray *subsections = [FXFormSection sectionsWithForm:subform controller:formController];
            [sections addObjectsFromArray:subsections];
            
            section = [subsections firstObject];
            if (!section.header) section.header = field.header ?: field.title;
            section.isSortable = field.isSortable;
            section = nil;
        }
        else
        {
            if (!section || field.header)
            {
                section = [[FXFormSection alloc] init];
                section.form = form;
                section.header = field.header;
                section.isSortable = ([form isKindOfClass:[FXTemplateForm class]] && ((FXTemplateForm *)form).field.isSortable);
                [sections addObject:section];
            }
            [section.fields addObject:field];
            if (field.footer)
            {
                section.footer = field.footer;
                section = nil;
            }
        }
    }
    return sections;
}

- (NSMutableArray *)fields
{
    if (!_fields)
    {
        _fields = [NSMutableArray array];
    }
    return _fields;
}

- (void)addNewField
{
    FXFormController *controller = [(FXFormField *)[_fields lastObject] formController];
    [(FXTemplateForm *)self.form addNewField];
    [_fields setArray:[FXFormField fieldsWithForm:self.form controller:controller]];
}

- (void)removeFieldAtIndex:(NSUInteger)index
{
    FXFormController *controller = [(FXFormField *)[_fields lastObject] formController];
    [(FXTemplateForm *)self.form removeFieldAtIndex:index];
    [_fields setArray:[FXFormField fieldsWithForm:self.form controller:controller]];
}

- (void)moveFieldAtIndex:(NSUInteger)index1 toIndex:(NSUInteger)index2
{
    FXFormController *controller = [(FXFormField *)[_fields lastObject] formController];
    [(FXTemplateForm *)self.form moveFieldAtIndex:index1 toIndex:index2];
    [_fields setArray:[FXFormField fieldsWithForm:self.form controller:controller]];
}

@end
