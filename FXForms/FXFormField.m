//
//  FXFormField.m
//  BasicExample
//
//  Created by Joseph Ridenour on 2/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormField.h"
#import "FXFormController.h"
#import "FXFormsDefines.h"
#import "FXFormModels.h"

#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma clang diagnostic ignored "-Wreceiver-is-weak"
#pragma clang diagnostic ignored "-Wconversion"
#pragma clang diagnostic ignored "-Wgnu"


@interface FXFormField ()

@property (nonatomic, strong) Class valueClass;
@property (nonatomic, strong) Class cellClass;
@property (nonatomic, readwrite) NSString *key;
@property (nonatomic, readwrite) NSArray *options;
@property (nonatomic, readwrite) NSDictionary *fieldTemplate;
@property (nonatomic, readwrite) BOOL isSortable;
@property (nonatomic, readwrite) BOOL isInline;
@property (nonatomic, readonly) id (^valueTransformer)(id input);
@property (nonatomic, readonly) id (^reverseValueTransformer)(id input);
@property (nonatomic, strong) id defaultValue;

@property (nonatomic, strong) NSMutableDictionary *cellConfig;

+ (NSArray *)fieldsWithForm:(id<FXForm>)form controller:(FXFormController *)formController;
- (instancetype)initWithForm:(id<FXForm>)form controller:(FXFormController *)formController attributes:(NSDictionary *)attributes;

@end

@implementation FXFormField

+ (NSArray *)fieldsWithForm:(id<FXForm>)form controller:(FXFormController *)formController
{
    //get fields
    NSArray *properties = FXFormProperties(form);
    NSMutableArray *fields = [[form fields] mutableCopy];
    if (!fields)
    {
        //use default fields
        fields = [NSMutableArray arrayWithArray:[properties valueForKey:FXFormFieldKey]];
    }
    
    //add extra fields
    [fields addObjectsFromArray:[form extraFields] ?: @[]];
    
    //process fields
    NSMutableDictionary *fieldDictionariesByKey = [NSMutableDictionary dictionary];
    for (NSDictionary *dict in properties)
    {
        fieldDictionariesByKey[dict[FXFormFieldKey]] = dict;
    }
    
    for (NSInteger i = [fields count] - 1; i >= 0; i--)
    {
        NSMutableDictionary *dictionary = nil;
        id dictionaryOrKey = fields[i];
        if ([dictionaryOrKey isKindOfClass:[NSString class]])
        {
            dictionaryOrKey = @{FXFormFieldKey: dictionaryOrKey};
        }
        if ([dictionaryOrKey isKindOfClass:[NSDictionary class]])
        {
            NSString *key = dictionaryOrKey[FXFormFieldKey];
            if ([[form excludedFields] containsObject:key])
            {
                //skip this field
                [fields removeObjectAtIndex:i];
                continue;
            }
            dictionary = [NSMutableDictionary dictionary];
            [dictionary addEntriesFromDictionary:fieldDictionariesByKey[key]];
            [dictionary addEntriesFromDictionary:dictionaryOrKey];
            NSString *selector = [key stringByAppendingString:@"Field"];
            if (selector && [form respondsToSelector:NSSelectorFromString(selector)])
            {
                [dictionary addEntriesFromDictionary:[(NSObject *)form valueForKey:selector]];
            }
            
            FXFormPreprocessFieldDictionary(dictionary);
        }
        else
        {
            [NSException raise:FXFormsException format:@"Unsupported field type: %@", [dictionaryOrKey class]];
        }
        fields[i] = [[self alloc] initWithForm:form controller:formController attributes:dictionary];
    }
    
    return fields;
}

- (instancetype)init
{
    //this class's contructor is private
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithForm:(id<FXForm>)form controller:(FXFormController *)formController attributes:(NSDictionary *)attributes
{
    if ((self = [super init]))
    {
        _form = form;
        _formController = formController;
        _cellConfig = [NSMutableDictionary dictionary];
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, __unused BOOL *stop) {
            [self setValue:value forKey:key];
        }];
    }
    return self;
}

- (BOOL)isIndexedType
{
    //return YES if value should be set as index of option, not value of option
    if ([self.valueClass isSubclassOfClass:[NSNumber class]] && ![self.type isEqualToString:FXFormFieldTypeBitfield])
    {
        return ![[self.options firstObject] isKindOfClass:[NSNumber class]];
    }
    return NO;
}

- (BOOL)isCollectionType
{
    for (Class valueClass in @[[NSArray class], [NSSet class], [NSOrderedSet class], [NSIndexSet class], [NSDictionary class]])
    {
        if ([self.valueClass isSubclassOfClass:valueClass]) return YES;
    }
    return NO;
}

- (BOOL)isOrderedCollectionType
{
    for (Class valueClass in @[[NSArray class], [NSOrderedSet class], [NSIndexSet class]])
    {
        if ([self.valueClass isSubclassOfClass:valueClass]) return YES;
    }
    return NO;
}

- (BOOL)isSubform
{
    return (![self.type isEqualToString:FXFormFieldTypeLabel] &&
            ([self.valueClass conformsToProtocol:@protocol(FXForm)] ||
             [self.valueClass isSubclassOfClass:[UIViewController class]] ||
             self.options || [self isCollectionType] || self.viewController));
}

- (NSString *)valueDescription:(id)value
{
    if (self.valueTransformer)
    {
        return [self.valueTransformer(value) fieldDescription];
    }
    
    if ([value isKindOfClass:[NSDate class]])
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        if ([self.type isEqualToString:FXFormFieldTypeDate])
        {
            formatter.dateStyle = NSDateFormatterMediumStyle;
            formatter.timeStyle = NSDateFormatterNoStyle;
        }
        else if ([self.type isEqualToString:FXFormFieldTypeTime])
        {
            formatter.dateStyle = NSDateFormatterNoStyle;
            formatter.timeStyle = NSDateFormatterMediumStyle;
        }
        else //datetime
        {
            formatter.dateStyle = NSDateFormatterShortStyle;
            formatter.timeStyle = NSDateFormatterShortStyle;
        }
        
        return [formatter stringFromDate:value];
    }
    
    return [value fieldDescription];
}

- (NSString *)fieldDescription
{
    NSString *descriptionKey = [self.key stringByAppendingString:@"FieldDescription"];
    if (descriptionKey && [self.form respondsToSelector:NSSelectorFromString(descriptionKey)])
    {
        return [(NSObject *)self.form valueForKey:descriptionKey];
    }
    
    if (self.options)
    {
        if ([self isIndexedType])
        {
            if (self.value)
            {
                return [self optionDescriptionAtIndex:[self.value integerValue] + (self.placeholder? 1: 0)];
            }
            else
            {
                return [self.placeholder fieldDescription];
            }
        }
        
        if ([self isCollectionType])
        {
            id value = self.value;
            if ([value isKindOfClass:[NSIndexSet class]])
            {
                NSMutableArray *options = [NSMutableArray array];
                [self.options enumerateObjectsUsingBlock:^(id option, NSUInteger i, __unused BOOL *stop) {
                    NSUInteger index = i;
                    if ([option isKindOfClass:[NSNumber class]])
                    {
                        index = [option integerValue];
                    }
                    if ([value containsIndex:index])
                    {
                        NSString *description = [self optionDescriptionAtIndex:i + (self.placeholder? 1: 0)];
                        if ([description length]) [options addObject:description];
                    }
                }];
                
                value = [options count]? options: nil;
            }
            else if (value && self.valueTransformer)
            {
                NSMutableArray *options = [NSMutableArray array];
                for (id option in value) {
                    [options addObject:self.valueTransformer(option)];
                }
                value = [options count]? options: nil;
            }
            
            return [value fieldDescription] ?: [self.placeholder fieldDescription];
        }
        else if ([self.type isEqual:FXFormFieldTypeBitfield])
        {
            NSUInteger value = [self.value integerValue];
            NSMutableArray *options = [NSMutableArray array];
            [self.options enumerateObjectsUsingBlock:^(id option, NSUInteger i, __unused BOOL *stop) {
                NSUInteger bit = 1 << i;
                if ([option isKindOfClass:[NSNumber class]])
                {
                    bit = [option integerValue];
                }
                if (value & bit)
                {
                    NSString *description = [self optionDescriptionAtIndex:i + (self.placeholder? 1: 0)];
                    if ([description length]) [options addObject:description];
                }
            }];
            
            return [options count]? [options fieldDescription]: [self.placeholder fieldDescription];
        }
        else if (self.placeholder && ![self.options containsObject:self.value])
        {
            return [self.placeholder description];
        }
    }
    
    return [self valueDescription:self.value];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return _cellConfig[key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    _cellConfig[key] = value;
}

- (id)valueWithoutDefaultSubstitution
{
    if (FXFormCanGetValueForKey(self.form, self.key))
    {
        id value = [(NSObject *)self.form valueForKey:self.key];
        if (value && self.options)
        {
            if ([self isIndexedType])
            {
                if ([value unsignedIntegerValue] >= [self.options count]) value = nil;
            }
            else if (![self isCollectionType] && ![self.type isEqualToString:FXFormFieldTypeBitfield])
            {
                //TODO: should we validate collection types too, or is that overkill?
                if (![self.options containsObject:value]) value = nil;
            }
        }
        return value;
    }
    return nil;
}

- (id)value
{
    if (FXFormCanGetValueForKey(self.form, self.key))
    {
        id value = [(NSObject *)self.form valueForKey:self.key];
        if (value && self.options)
        {
            if ([self isIndexedType])
            {
                if ([value unsignedIntegerValue] >= [self.options count]) value = nil;
            }
            else if (![self isCollectionType] && ![self.type isEqualToString:FXFormFieldTypeBitfield])
            {
                //TODO: should we validate collection types too, or is that overkill?
                if (![self.options containsObject:value]) value = nil;
            }
        }
        if (!value && self.defaultValue)
        {
            self.value = value = self.defaultValue;
        }
        return value;
    }
    return self.defaultValue;
}

- (void)setValue:(id)value
{
    if (FXFormCanSetValueForKey(self.form, self.key))
    {
        //use default value if available
        value = value ?: self.defaultValue;
        
        if (self.reverseValueTransformer && ![self isCollectionType] && !self.options)
        {
            value = self.reverseValueTransformer(value);
        }
        else if ([value isKindOfClass:[NSString class]])
        {
            if ([self.type isEqualToString:FXFormFieldTypeNumber] ||
                [self.type isEqualToString:FXFormFieldTypeFloat])
            {
                value = [(NSString *)value length]? @([value doubleValue]): nil;
            }
            else if ([self.type isEqualToString:FXFormFieldTypeInteger] ||
                     [self.type isEqualToString:FXFormFieldTypeUnsigned])
            {
                //NOTE: unsignedLongLongValue doesn't exist on NSString
                value = [(NSString *)value length]? @([value longLongValue]): nil;
            }
            else if ([self.valueClass isSubclassOfClass:[NSURL class]])
            {
                value = [self.valueClass URLWithString:value];
            }
        }
        else if ([self.valueClass isSubclassOfClass:[NSString class]])
        {
            //handle case where value is numeric but value class is string
            value = [value description];
        }
        
        if (self.valueClass == [NSMutableString class])
        {
            //replace string or make mutable copy of it
            id _value = [self valueWithoutDefaultSubstitution];
            if (_value)
            {
                [(NSMutableString *)_value setString:value];
                value = _value;
            }
            else
            {
                value = [NSMutableString stringWithString:value];
            }
        }
        
        if (!value)
        {
            for (NSDictionary *field in FXFormProperties(self.form))
            {
                if ([field[FXFormFieldKey] isEqualToString:self.key])
                {
                    if ([@[FXFormFieldTypeBoolean, FXFormFieldTypeInteger,
                           FXFormFieldTypeUnsigned, FXFormFieldTypeFloat] containsObject:field[FXFormFieldType]])
                    {
                        //prevents NSInvalidArgumentException in setNilValueForKey: method
                        value = [self isIndexedType]? @(NSNotFound): @0;
                    }
                    break;
                }
            }
        }
        
        [(NSObject *)self.form setValue:value forKey:self.key];
    }
}

- (void)setValueTransformer:(id)valueTransformer
{
    if ([valueTransformer isKindOfClass:[NSString class]])
    {
        valueTransformer = FXFormClassFromString(valueTransformer);
    }
    if ([valueTransformer class] == valueTransformer)
    {
        valueTransformer = [[valueTransformer alloc] init];
    }
    if ([valueTransformer isKindOfClass:[NSValueTransformer class]])
    {
        NSValueTransformer *transformer = valueTransformer;
        valueTransformer = ^(id input)
        {
            return [transformer transformedValue:input];
        };
        if ([[transformer class] allowsReverseTransformation])
        {
            _reverseValueTransformer = ^(id input)
            {
                return [transformer reverseTransformedValue:input];
            };
        }
    }
    
    _valueTransformer = [valueTransformer copy];
}

- (void)setAction:(id)action
{
    if ([action isKindOfClass:[NSString class]])
    {
        SEL selector = NSSelectorFromString(action);
        __weak FXFormField *weakSelf = self;
        action = ^(id sender)
        {
            [weakSelf.formController performAction:selector withSender:sender];
        };
    }
    
    _action = [action copy];
}

- (void)setSegue:(id)segue
{
    if ([segue isKindOfClass:[NSString class]])
    {
        segue = FXFormClassFromString(segue) ?: [segue copy];
    }
    
    NSAssert(segue != [UIStoryboardPopoverSegue class], @"Unfortunately displaying subcontrollers using UIStoryboardPopoverSegue is not supported, as doing so would require calling private methods. To display using a popover, create a custom UIStoryboard subclass instead.");
    
    _segue = segue;
}

- (void)setClass:(Class)valueClass
{
    _valueClass = valueClass;
}

- (void)setCell:(Class)cellClass
{
    _cellClass = cellClass;
}

- (void)setDefault:(id)defaultValue
{
    _defaultValue = defaultValue;
}

- (void)setInline:(BOOL)isInline
{
    _isInline = isInline;
}

- (void)setOptions:(NSArray *)options
{
    _options = [options count]? [options copy]: nil;
}

- (void)setTemplate:(NSDictionary *)template
{
    _fieldTemplate = [template copy];
}

- (void)setSortable:(BOOL)sortable
{
    _isSortable = sortable;
}

- (void)setHeader:(id)header
{
    if ([header class] == header)
    {
        header = [[header alloc] init];
    }
    _header = header;
}

- (void)setFooter:(id)footer
{
    if ([footer class] == footer)
    {
        footer = [[footer alloc] init];
    }
    _footer = footer;
}

- (BOOL)isSortable
{
    return _isSortable &&
    ([self.valueClass isSubclassOfClass:[NSArray class]] ||
     [self.valueClass isSubclassOfClass:[NSOrderedSet class]]);
}

#pragma mark -
#pragma mark Option helpers

- (NSUInteger)optionCount
{
    NSUInteger count = [self.options count];
    return count? count + (self.placeholder? 1: 0): 0;
}

- (id)optionAtIndex:(NSUInteger)index
{
    if (index == 0)
    {
        return self.placeholder ?: self.options[0];
    }
    else
    {
        return self.options[index - (self.placeholder? 1: 0)];
    }
}

- (NSUInteger)indexOfOption:(id)option
{
    NSUInteger index = [self.options indexOfObject:option];
    if (index == NSNotFound)
    {
        return self.placeholder? 0: NSNotFound;
    }
    else
    {
        return index + (self.placeholder? 1: 0);
    }
}

- (NSString *)optionDescriptionAtIndex:(NSUInteger)index
{
    if (index == 0)
    {
        return self.placeholder? [self.placeholder fieldDescription]: [self valueDescription:self.options[0]];
    }
    else
    {
        return [self valueDescription:self.options[index - (self.placeholder? 1: 0)]];
    }
}

- (void)setOptionSelected:(BOOL)selected atIndex:(NSUInteger)index
{
    if (self.placeholder)
    {
        index = (index == 0)? NSNotFound: index - 1;
    }
    
    if ([self isCollectionType])
    {
        BOOL copyNeeded = ([NSStringFromClass(self.valueClass) rangeOfString:@"Mutable"].location == NSNotFound);
        
        id collection = self.value ?: [[self.valueClass alloc] init];
        if (copyNeeded) collection = [collection mutableCopy];
        
        if (index == NSNotFound)
        {
            collection = nil;
        }
        else if ([self.valueClass isSubclassOfClass:[NSIndexSet class]])
        {
            if (selected)
            {
                [collection addIndex:index];
            }
            else
            {
                [collection removeIndex:index];
            }
        }
        else if ([self.valueClass isSubclassOfClass:[NSDictionary class]])
        {
            if (selected)
            {
                collection[@(index)] = self.options[index];
            }
            else
            {
                [(NSMutableDictionary *)collection removeObjectForKey:@(index)];
            }
        }
        else
        {
            //need to preserve order for ordered collections
            [collection removeAllObjects];
            [self.options enumerateObjectsUsingBlock:^(id option, NSUInteger i, __unused BOOL *stop) {
                
                if (i == index)
                {
                    if (selected) [collection addObject:option];
                }
                else if ([self.value containsObject:option])
                {
                    [collection addObject:option];
                }
            }];
        }
        
        if (copyNeeded) collection = [collection copy];
        self.value = collection;
    }
    else if ([self.type isEqualToString:FXFormFieldTypeBitfield])
    {
        if (index == NSNotFound)
        {
            self.value = @0;
        }
        else
        {
            if ([self.options[index] isKindOfClass:[NSNumber class]])
            {
                index = [self.options[index] integerValue];
            }
            else
            {
                index = 1 << index;
            }
            if (selected)
            {
                self.value = @([self.value integerValue] | index);
            }
            else
            {
                self.value = @([self.value integerValue] ^ index);
            }
        }
    }
    else if ([self isIndexedType])
    {
        if (selected)
        {
            self.value = @(index);
        }
        //cannot deselect
    }
    else if (index != NSNotFound)
    {
        if (selected)
        {
            self.value = self.options[index];
        }
        //cannot deselect
    }
    else
    {
        self.value = nil;
    }
}

- (BOOL)isOptionSelectedAtIndex:(NSUInteger)index
{
    if (self.placeholder)
    {
        index = (index == 0)? NSNotFound: index - 1;
    }
    
    id option = (index == NSNotFound)? nil: self.options[index];
    if ([self isCollectionType])
    {
        if (index == NSNotFound)
        {
            //true if no option selected
            return [(NSArray *)self.value count] == 0;
        }
        else if ([self.valueClass isSubclassOfClass:[NSIndexSet class]])
        {
            if ([option isKindOfClass:[NSNumber class]])
            {
                index = [option integerValue];
            }
            return [(NSIndexSet *)self.value containsIndex:index];
        }
        else
        {
            return [(NSArray *)self.value containsObject:option];
        }
    }
    else if ([self.type isEqualToString:FXFormFieldTypeBitfield])
    {
        if (index == NSNotFound)
        {
            //true if not numeric
            return ![self.value integerValue];
        }
        else if ([option isKindOfClass:[NSNumber class]])
        {
            index = [option integerValue];
        }
        else
        {
            index = 1 << index;
        }
        return ([self.value integerValue] & index) != 0;
    }
    else if ([self isIndexedType])
    {
        return self.value? [self.value unsignedIntegerValue] == index: !option;
    }
    else
    {
        return option? [option isEqual:self.value]: !self.value;
    }
}

@end
