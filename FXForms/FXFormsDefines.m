//
//  FXFormsDefines.m
//  BasicExample
//
//  Created by Joseph Ridenour on 2/19/15.
//  Copyright (c) 2015 Charcoal Design. All rights reserved.
//

#import "FXFormsDefines.h"
#import <objc/runtime.h>

#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma clang diagnostic ignored "-Wreceiver-is-weak"
#pragma clang diagnostic ignored "-Wconversion"
#pragma clang diagnostic ignored "-Wgnu"


NSString *const FXFormFieldKey = @"key";
NSString *const FXFormFieldType = @"type";
NSString *const FXFormFieldClass = @"class";
NSString *const FXFormFieldCell = @"cell";
NSString *const FXFormFieldTitle = @"title";
NSString *const FXFormFieldPlaceholder = @"placeholder";
NSString *const FXFormFieldDefaultValue = @"default";
NSString *const FXFormFieldOptions = @"options";
NSString *const FXFormFieldTemplate = @"template";
NSString *const FXFormFieldValueTransformer = @"valueTransformer";
NSString *const FXFormFieldAction = @"action";
NSString *const FXFormFieldSegue = @"segue";
NSString *const FXFormFieldHeader = @"header";
NSString *const FXFormFieldFooter = @"footer";
NSString *const FXFormFieldInline = @"inline";
NSString *const FXFormFieldSortable = @"sortable";
NSString *const FXFormFieldViewController = @"viewController";

NSString *const FXFormFieldTypeDefault = @"default";
NSString *const FXFormFieldTypeLabel = @"label";
NSString *const FXFormFieldTypeText = @"text";
NSString *const FXFormFieldTypeLongText = @"longtext";
NSString *const FXFormFieldTypeURL = @"url";
NSString *const FXFormFieldTypeEmail = @"email";
NSString *const FXFormFieldTypePhone = @"phone";
NSString *const FXFormFieldTypePassword = @"password";
NSString *const FXFormFieldTypeNumber = @"number";
NSString *const FXFormFieldTypeInteger = @"integer";
NSString *const FXFormFieldTypeUnsigned = @"unsigned";
NSString *const FXFormFieldTypeFloat = @"float";
NSString *const FXFormFieldTypeBitfield = @"bitfield";
NSString *const FXFormFieldTypeBoolean = @"boolean";
NSString *const FXFormFieldTypeOption = @"option";
NSString *const FXFormFieldTypeDate = @"date";
NSString *const FXFormFieldTypeTime = @"time";
NSString *const FXFormFieldTypeDateTime = @"datetime";
NSString *const FXFormFieldTypeImage = @"image";


NSString *const FXFormsException = @"FXFormsException";


const CGFloat FXFormFieldLabelSpacing = 5;
const CGFloat FXFormFieldMinLabelWidth = 97;
const CGFloat FXFormFieldMaxLabelWidth = 240;
const CGFloat FXFormFieldMinFontSize = 12;
const CGFloat FXFormFieldPaddingLeft = 10;
const CGFloat FXFormFieldPaddingRight = 10;
const CGFloat FXFormFieldPaddingTop = 12;
const CGFloat FXFormFieldPaddingBottom = 12;


Class FXFormClassFromString(NSString *className)
{
    Class cls = NSClassFromString(className);
    if (className && !cls)
    {
        //might be a Swift class; time for some hackery!
        className = [@[[[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleNameKey],
                       className] componentsJoinedByString:@"."];
        //try again
        cls = NSClassFromString(className);
    }
    return cls;
}

UIView *FXFormsFirstResponder(UIView *view)
{
    if ([view isFirstResponder])
    {
        return view;
    }
    for (UIView *subview in view.subviews)
    {
        UIView *responder = FXFormsFirstResponder(subview);
        if (responder)
        {
            return responder;
        }
    }
    return nil;
}


#pragma mark -
#pragma mark Models


CGFloat FXFormLabelMinFontSize(UILabel *label)
{
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
    
    if (![label respondsToSelector:@selector(setMinimumScaleFactor:)])
    {
        return label.minimumFontSize;
    }
    
#endif
    
    return label.font.pointSize * label.minimumScaleFactor;
}

void FXFormLabelSetMinFontSize(UILabel *label, CGFloat fontSize)
{
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
    
    if (![label respondsToSelector:@selector(setMinimumScaleFactor:)])
    {
        label.minimumFontSize = fontSize;
    }
    else
        
#endif
        
    {
        label.minimumScaleFactor = fontSize / label.font.pointSize;
    }
}

NSArray *FXFormProperties(id<FXForm> form)
{
    if (!form) return nil;
    
    static void *FXFormPropertiesKey = &FXFormPropertiesKey;
    NSMutableArray *properties = objc_getAssociatedObject(form, FXFormPropertiesKey);
    if (!properties)
    {
        static NSSet *NSObjectProperties;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSObjectProperties = [NSMutableSet setWithArray:@[@"description", @"debugDescription", @"hash", @"superclass"]];
            unsigned int propertyCount;
            objc_property_t *propertyList = class_copyPropertyList([NSObject class], &propertyCount);
            for (unsigned int i = 0; i < propertyCount; i++)
            {
                //get property name
                objc_property_t property = propertyList[i];
                const char *propertyName = property_getName(property);
                [(NSMutableSet *)NSObjectProperties addObject:@(propertyName)];
            }
            free(propertyList);
            NSObjectProperties = [NSObjectProperties copy];
        });
        
        properties = [NSMutableArray array];
        Class subclass = [form class];
        while (subclass != [NSObject class])
        {
            unsigned int propertyCount;
            objc_property_t *propertyList = class_copyPropertyList(subclass, &propertyCount);
            for (unsigned int i = 0; i < propertyCount; i++)
            {
                //get property name
                objc_property_t property = propertyList[i];
                const char *propertyName = property_getName(property);
                NSString *key = @(propertyName);
                
                //ignore NSObject properties, unless overridden as readwrite
                char *readonly = property_copyAttributeValue(property, "R");
                if (readonly)
                {
                    free(readonly);
                    if ([NSObjectProperties containsObject:key])
                    {
                        continue;
                    }
                }
                
                //get property type
                Class valueClass = nil;
                NSString *valueType = nil;
                char *typeEncoding = property_copyAttributeValue(property, "T");
                switch (typeEncoding[0])
                {
                    case '@':
                    {
                        if (strlen(typeEncoding) >= 3)
                        {
                            char *className = strndup(typeEncoding + 2, strlen(typeEncoding) - 3);
                            __autoreleasing NSString *name = @(className);
                            NSRange range = [name rangeOfString:@"<"];
                            if (range.location != NSNotFound)
                            {
                                name = [name substringToIndex:range.location];
                            }
                            valueClass = FXFormClassFromString(name) ?: [NSObject class];
                            free(className);
                        }
                        break;
                    }
                    case 'c':
                    case 'B':
                    {
                        valueClass = [NSNumber class];
                        valueType = FXFormFieldTypeBoolean;
                        break;
                    }
                    case 'i':
                    case 's':
                    case 'l':
                    case 'q':
                    {
                        valueClass = [NSNumber class];
                        valueType = FXFormFieldTypeInteger;
                        break;
                    }
                    case 'C':
                    case 'I':
                    case 'S':
                    case 'L':
                    case 'Q':
                    {
                        valueClass = [NSNumber class];
                        valueType = FXFormFieldTypeUnsigned;
                        break;
                    }
                    case 'f':
                    case 'd':
                    {
                        valueClass = [NSNumber class];
                        valueType = FXFormFieldTypeFloat;
                        break;
                    }
                    case '{': //struct
                    case '(': //union
                    {
                        valueClass = [NSValue class];
                        valueType = FXFormFieldTypeLabel;
                        break;
                    }
                    case ':': //selector
                    case '#': //class
                    default:
                    {
                        valueClass = nil;
                        valueType = nil;
                    }
                }
                free(typeEncoding);
                
                //add to properties
                NSMutableDictionary *inferred = [NSMutableDictionary dictionaryWithObject:key forKey:FXFormFieldKey];
                if (valueClass) inferred[FXFormFieldClass] = valueClass;
                if (valueType) inferred[FXFormFieldType] = valueType;
                [properties addObject:[inferred copy]];
            }
            free(propertyList);
            subclass = [subclass superclass];
        }
        objc_setAssociatedObject(form, FXFormPropertiesKey, properties, OBJC_ASSOCIATION_RETAIN);
    }
    return properties;
}

BOOL FXFormOverridesSelector(id<FXForm> form, SEL selector)
{
    Class formClass = [form class];
    while (formClass && formClass != [NSObject class])
    {
        unsigned int numberOfMethods;
        Method *methods = class_copyMethodList(formClass, &numberOfMethods);
        for (unsigned int i = 0; i < numberOfMethods; i++)
        {
            if (method_getName(methods[i]) == selector)
            {
                free(methods);
                return YES;
            }
        }
        if (methods) free(methods);
        formClass = [formClass superclass];
    }
    return NO;
}

BOOL FXFormCanGetValueForKey(id<FXForm> form, NSString *key)
{
    //has key?
    if (![key length])
    {
        return NO;
    }
    
    //does a property exist for it?
    if ([[FXFormProperties(form) valueForKey:FXFormFieldKey] containsObject:key])
    {
        return YES;
    }
    
    //is there a getter method for this key?
    if ([form respondsToSelector:NSSelectorFromString(key)])
    {
        return YES;
    }
    
    //does it override valueForKey?
    if (FXFormOverridesSelector(form, @selector(valueForKey:)))
    {
        return YES;
    }
    
    //does it override valueForUndefinedKey?
    if (FXFormOverridesSelector(form, @selector(valueForUndefinedKey:)))
    {
        return YES;
    }
    
    //it will probably crash
    return NO;
}

BOOL FXFormCanSetValueForKey(id<FXForm> form, NSString *key)
{
    //has key?
    if (![key length])
    {
        return NO;
    }
    
    //does a property exist for it?
    if ([[FXFormProperties(form) valueForKey:FXFormFieldKey] containsObject:key])
    {
        return YES;
    }
    
    //is there a setter method for this key?
    if ([form respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [[key substringToIndex:1] uppercaseString], [key substringFromIndex:1]])])
    {
        return YES;
    }
    
    //does it override setValueForKey?
    if (FXFormOverridesSelector(form, @selector(setValue:forKey:)))
    {
        return YES;
    }
    
    //does it override setValue:forUndefinedKey?
    if (FXFormOverridesSelector(form, @selector(setValue:forUndefinedKey:)))
    {
        return YES;
    }
    
    //it will probably crash
    return NO;
}

NSString *FXFormFieldInferType(NSDictionary *dictionary)
{
    //guess type from class
    Class valueClass = dictionary[FXFormFieldClass];
    if ([valueClass isSubclassOfClass:[NSURL class]])
    {
        return FXFormFieldTypeURL;
    }
    else if ([valueClass isSubclassOfClass:[NSNumber class]])
    {
        return FXFormFieldTypeNumber;
    }
    else if ([valueClass isSubclassOfClass:[NSDate class]])
    {
        return FXFormFieldTypeDate;
    }
    else if ([valueClass isSubclassOfClass:[UIImage class]])
    {
        return FXFormFieldTypeImage;
    }
    
    if (!valueClass && ! dictionary[FXFormFieldAction] && !dictionary[FXFormFieldSegue])
    {
        //assume string if there's no action and nothing else to go on
        valueClass = [NSString class];
    }
    
    //guess type from key name
    if ([valueClass isSubclassOfClass:[NSString class]])
    {
        NSString *key = dictionary[FXFormFieldKey];
        NSString *lowercaseKey = [key lowercaseString];
        if ([lowercaseKey hasSuffix:@"password"])
        {
            return FXFormFieldTypePassword;
        }
        else if ([lowercaseKey hasSuffix:@"email"] || [lowercaseKey hasSuffix:@"emailaddress"])
        {
            return FXFormFieldTypeEmail;
        }
        else if ([lowercaseKey hasSuffix:@"phone"] || [lowercaseKey hasSuffix:@"phonenumber"])
        {
            return FXFormFieldTypePhone;
        }
        else if ([lowercaseKey hasSuffix:@"url"] || [lowercaseKey hasSuffix:@"link"])
        {
            return FXFormFieldTypeURL;
        }
        else if (valueClass)
        {
            //only return text type if there's no action and no better guess
            return FXFormFieldTypeText;
        }
    }
    
    return FXFormFieldTypeDefault;
}

Class FXFormFieldInferClass(NSDictionary *dictionary)
{
    //if there are options, type should match first option
    NSArray *options = dictionary[FXFormFieldOptions];
    if ([options count])
    {
        //use same type as options
        return [[options firstObject] classForCoder];
    }
    
    //attempt to determine class from type
    NSString *type = dictionary[FXFormFieldType] ?: FXFormFieldInferType(dictionary);
    return @{FXFormFieldTypeLabel: [NSString class],
             FXFormFieldTypeText: [NSString class],
             FXFormFieldTypeLongText: [NSString class],
             FXFormFieldTypeURL: [NSURL class],
             FXFormFieldTypeEmail: [NSString class],
             FXFormFieldTypePhone: [NSString class],
             FXFormFieldTypePassword: [NSString class],
             FXFormFieldTypeNumber: [NSNumber class],
             FXFormFieldTypeInteger: [NSNumber class],
             FXFormFieldTypeUnsigned: [NSNumber class],
             FXFormFieldTypeFloat: [NSNumber class],
             FXFormFieldTypeBitfield: [NSNumber class],
             FXFormFieldTypeBoolean: [NSNumber class],
             FXFormFieldTypeOption: [NSNumber class],
             FXFormFieldTypeDate: [NSDate class],
             FXFormFieldTypeTime: [NSDate class],
             FXFormFieldTypeDateTime: [NSDate class],
             FXFormFieldTypeImage: [UIImage class]
             }[type];
}

void FXFormPreprocessFieldDictionary(NSMutableDictionary *dictionary)
{
    //use base cell for subforms
    NSString *type = dictionary[FXFormFieldType];
    NSArray *options = dictionary[FXFormFieldOptions];
    if ((options || dictionary[FXFormFieldViewController] || dictionary[FXFormFieldTemplate]) &&
        ![type isEqualToString:FXFormFieldTypeBitfield] && ![dictionary[FXFormFieldInline] boolValue])
    {
        //TODO: is there a good way to support custom type for non-inline options cells?
        //TODO: is there a better way to force non-inline cells to use base cell?
        dictionary[FXFormFieldType] = type = FXFormFieldTypeDefault;
    }
    
    //get field value class
    id valueClass = dictionary[FXFormFieldClass];
    if ([valueClass isKindOfClass:[NSString class]])
    {
        dictionary[FXFormFieldClass] = valueClass = FXFormClassFromString(valueClass);
    }
    else if (!valueClass && (valueClass = FXFormFieldInferClass(dictionary)))
    {
        dictionary[FXFormFieldClass] = valueClass;
    }
    
    //get default value
    id defaultValue = dictionary[FXFormFieldDefaultValue];
    if (defaultValue)
    {
        if ([valueClass isSubclassOfClass:[NSArray class]] && ![defaultValue isKindOfClass:[NSArray class]])
        {
            //workaround for common mistake where type is collection, but default value is a single value
            defaultValue = [valueClass arrayWithObject:defaultValue];
        }
        else if ([valueClass isSubclassOfClass:[NSSet class]] && ![defaultValue isKindOfClass:[NSSet class]])
        {
            //as above, but for NSSet
            defaultValue = [valueClass setWithObject:defaultValue];
        }
        else if ([valueClass isSubclassOfClass:[NSOrderedSet class]] && ![defaultValue isKindOfClass:[NSOrderedSet class]])
        {
            //as above, but for NSOrderedSet
            defaultValue = [valueClass orderedSetWithObject:defaultValue];
        }
        dictionary[FXFormFieldDefaultValue] = defaultValue;
    }
    
    //get field type
    NSString *key = dictionary[FXFormFieldKey];
    if (!type)
    {
        dictionary[FXFormFieldType] = type = FXFormFieldInferType(dictionary);
    }
    
    //convert cell from string to class
    id cellClass = dictionary[FXFormFieldCell];
    if ([cellClass isKindOfClass:[NSString class]])
    {
        dictionary[FXFormFieldCell] = cellClass = FXFormClassFromString(cellClass);
    }
    
    //convert view controller from string to class
    id viewController = dictionary[FXFormFieldViewController];
    if ([viewController isKindOfClass:[NSString class]])
    {
        dictionary[FXFormFieldViewController] = viewController = FXFormClassFromString(viewController);
    }
    
    //convert header from string to class
    id header = dictionary[FXFormFieldHeader];
    if ([header isKindOfClass:[NSString class]])
    {
        Class viewClass = FXFormClassFromString(header);
        if ([viewClass isSubclassOfClass:[UIView class]])
        {
            dictionary[FXFormFieldHeader] = viewClass;
        }
        else
        {
            dictionary[FXFormFieldHeader] = [header copy];
        }
    }
    else if ([header isKindOfClass:[NSNull class]])
    {
        dictionary[FXFormFieldHeader] = @"";
    }
    
    //convert footer from string to class
    id footer = dictionary[FXFormFieldFooter];
    if ([footer isKindOfClass:[NSString class]])
    {
        Class viewClass = FXFormClassFromString(footer);
        if ([viewClass isSubclassOfClass:[UIView class]])
        {
            dictionary[FXFormFieldFooter] = viewClass;
        }
        else
        {
            dictionary[FXFormFieldFooter] = [footer copy];
        }
    }
    else if ([footer isKindOfClass:[NSNull class]])
    {
        dictionary[FXFormFieldFooter] = @"";
    }
    
    //preprocess template dictionary
    NSDictionary *template = dictionary[FXFormFieldTemplate];
    if (template)
    {
        template = [NSMutableDictionary dictionaryWithDictionary:template];
        FXFormPreprocessFieldDictionary((NSMutableDictionary *)template);
        dictionary[FXFormFieldTemplate] = template;
    }
    
    //derive title from key or selector name
    if (!dictionary[FXFormFieldTitle])
    {
        BOOL wasCapital = YES;
        NSString *keyOrAction = key;
        if (!keyOrAction && [dictionary[FXFormFieldAction] isKindOfClass:[NSString class]])
        {
            keyOrAction = dictionary[FXFormFieldAction];
        }
        NSMutableString *output = nil;
        if (keyOrAction)
        {
            output = [NSMutableString stringWithString:[[keyOrAction substringToIndex:1] uppercaseString]];
            for (NSUInteger j = 1; j < [keyOrAction length]; j++)
            {
                unichar character = [keyOrAction characterAtIndex:j];
                BOOL isCapital = ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:character]);
                if (isCapital && !wasCapital) [output appendString:@" "];
                wasCapital = isCapital;
                if (character != ':') [output appendFormat:@"%C", character];
            }
        }
        if ([output length])
        {
            dictionary[FXFormFieldTitle] = NSLocalizedString(output, nil);
        }
    }
}






@implementation NSObject (FXForms)

- (NSString *)fieldDescription
{
    for (Class fieldClass in @[[NSString class], [NSNumber class], [NSDate class]])
    {
        if ([self isKindOfClass:fieldClass])
        {
            return [self description];
        }
    }
    for (Class fieldClass in @[[NSDictionary class], [NSArray class], [NSSet class], [NSOrderedSet class]])
    {
        if ([self isKindOfClass:fieldClass])
        {
            id collection = self;
            if (fieldClass == [NSDictionary class])
            {
                collection = [collection allValues];
            }
            NSMutableArray *array = [NSMutableArray array];
            for (id object in collection)
            {
                NSString *description = [object fieldDescription];
                if ([description length]) [array addObject:description];
            }
            return [array componentsJoinedByString:@", "];
        }
    }
    if ([self isKindOfClass:[NSDate class]])
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        return [formatter stringFromDate:(NSDate *)self];
    }
    return @"";
}

- (NSArray *)fields
{
    return nil;
}

- (NSArray *)extraFields
{
    return nil;
}

- (NSArray *)excludedFields
{
    return nil;
}

@end

