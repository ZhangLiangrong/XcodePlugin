//
//  DeallocCommond.m
//  VCXcodePlugin
//
//  Created by Vic Zhang on 15/4/11.
//  Copyright (c) 2015 ___Company Name___. All rights reserved.
//

#import "DeallocCommond.h"
#import "FormatCommand.h"
#import "FileSearchHelper.h"

@implementation DeallocCommond

+(NSString*)interfaceNameForString:(NSString*)textString location:(NSInteger)location end:(NSInteger)end
{
    for(NSInteger i = location; i < end; i++){
        if([[textString substringWithRange:NSMakeRange(i, 1)] isEqualToString:@":"] || [[textString substringWithRange:NSMakeRange(i, 1)] isEqualToString:@"("]){
            return [[textString substringWithRange:NSMakeRange(location, i - location)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
    }
    return nil;
}
+(NSString*)implementationNameForString:(NSString*)textString end:(NSInteger)end
{
    NSRange lastFind = NSMakeRange(NSNotFound, 0);
    NSInteger findStart = 0;
    while(findStart < end){
        NSRange implementationRange = [textString rangeOfString:@"@implementation" options:NSCaseInsensitiveSearch range:NSMakeRange(findStart,end - findStart)];
        findStart = implementationRange.location + implementationRange.length;
        if(implementationRange.location != NSNotFound){
            lastFind = implementationRange;
        }else{
            break;
        }
    }
    if(lastFind.location != NSNotFound){
        for(NSInteger i = lastFind.location + lastFind.length; i < end; i++){
            if([[textString substringWithRange:NSMakeRange(i, 1)] isEqualToString:@"\n"] || [[textString substringWithRange:NSMakeRange(i, 1)] isEqualToString:@"("]){
                return [[textString substringWithRange:NSMakeRange(lastFind.location + lastFind.length, i - lastFind.location - lastFind.length)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
        }
    }
    return nil;
}
+(NSArray*)importHeaderArrayForString:(NSString*)textString
{
    NSMutableArray *headersArray = [NSMutableArray array];
    NSRange interfaceRange = [textString rangeOfString:@"@interface"];
    NSRange implementRange = [textString rangeOfString:@"@implementation"];
    NSInteger findStart = 0;
    NSInteger max = MIN(textString.length,MIN(interfaceRange.location, implementRange.location));
    while(findStart < max){
        NSRange importRange = [textString rangeOfString:@"#import" options:NSCaseInsensitiveSearch range:NSMakeRange(findStart, max - findStart)];
        if(importRange.location != NSNotFound){
            NSRange endRange = [textString rangeOfString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(importRange.location + importRange.length, max - importRange.location - importRange.length)];
            NSRange leftRange = [textString rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(importRange.location + importRange.length, max - importRange.location - importRange.length)];
            if(leftRange.location != NSNotFound){
                NSRange rightRange = [textString rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(leftRange.location + leftRange.length, max - leftRange.location - leftRange.length)];
                if(leftRange.location != NSNotFound && rightRange.location != NSNotFound ){
                    if(rightRange.location > endRange.location || leftRange.location > endRange.location){
                        findStart = endRange.location + endRange.length;
                        continue;
                    }
                    NSString *file = [textString substringWithRange:NSMakeRange(leftRange.location + leftRange.length, rightRange.location - leftRange.location - leftRange.length)];
                    [headersArray addObject:file];
                    findStart = rightRange.location + rightRange.length;
                    continue;
                }
            }else{
                findStart = endRange.location + endRange.length;
                continue;
            }
        }
        break;
    }
    return headersArray;
}

+(NSString*)deallocString:(NSString*)textString currentLocation:(NSInteger)currentLocation
{
    NSMutableString *resultString = [NSMutableString string];
    NSMutableArray *allPropertyArray = [NSMutableArray array];
    NSMutableArray *allVarArray = [NSMutableArray array];
    NSString *implementationName = [self implementationNameForString:textString end:currentLocation];
    if([implementationName length] > 0){
        [self generatePropertyAndVarArrayForTextString:textString implementationName:implementationName savePropertyArray:allPropertyArray saveVarArray:allVarArray];
        NSArray *headerArray = [self importHeaderArrayForString:textString];
        NSArray *searchContentArray = [FileSearchHelper searchWorkspaceForFiles:headerArray];
        if(searchContentArray.count > 0){
            for(NSString *textString in searchContentArray){
                BOOL isFind = [self generatePropertyAndVarArrayForTextString:textString implementationName:implementationName savePropertyArray:allPropertyArray saveVarArray:allVarArray];
                if(isFind){
                    break;
                }
            }
        }
        [self removeVarArrayFromExitedPropertyArray:allPropertyArray varArray:allVarArray];
        NSString *newCode = [self generateDeallocCodeForPropertyArray:allPropertyArray varArray:allVarArray interfaceName:implementationName];
        if(newCode.length > 0){
            [resultString appendString:newCode];
        }
    }
    return resultString;
}

+(void)removeVarArrayFromExitedPropertyArray:(NSMutableArray*)propertyArray varArray:(NSMutableArray*)varArray
{
    for(NSInteger i = varArray.count - 1; i>= 0 ; i--){
        NSString *var = [varArray objectAtIndex:i];
        for(NSString *property in propertyArray){
            if([property isEqualToString:var] || [[NSString stringWithFormat:@"_%@",property] isEqualToString:var]){
                [varArray removeObjectAtIndex:i];
                break;
            }
        }
    }
}

+(BOOL)generatePropertyAndVarArrayForTextString:(NSString*)textString implementationName:(NSString*)implementationName savePropertyArray:(NSMutableArray*)allPropertyArray saveVarArray:(NSMutableArray*)allVarArray
{
    BOOL isFind = NO;
    NSInteger location = 0;
    NSString *findInterfaceName = nil;
    while (location < textString.length && !isFind) {
        NSRange interfaceRange = [textString rangeOfString:@"@interface" options:NSCaseInsensitiveSearch range:NSMakeRange(location, textString.length - location)];
        NSRange endRange = [textString rangeOfString:@"@end" options:NSCaseInsensitiveSearch range:NSMakeRange(location, textString.length - location)];
        findInterfaceName = [self interfaceNameForString:textString location:interfaceRange.location + interfaceRange.length end:endRange.location];
        isFind = [findInterfaceName isEqualToString:implementationName];
        if(isFind  && interfaceRange.location != NSNotFound && endRange.location != NSNotFound && endRange.location > interfaceRange.location + interfaceRange.length){
            NSInteger findStart = interfaceRange.location + interfaceRange.length + 1;
            NSArray *propertyArray = [self findPropertyArray:textString location:findStart end:endRange.location];
            [allPropertyArray addObjectsFromArray:propertyArray];
            NSArray *varArray = [self findVarArray:textString location:findStart end:endRange.location];
            [allVarArray addObjectsFromArray:varArray];
        }
        location = endRange.location + endRange.length;
    }
    return isFind;
}

+(NSArray*)findVarArray:(NSString*)textString location:(NSInteger)findStart end:(NSInteger)end
{
    NSMutableArray *varArray = [NSMutableArray array];
    NSRange leftBraceRange = [textString rangeOfString:@"{" options:NSCaseInsensitiveSearch range:NSMakeRange(findStart, end - findStart)];
    if(leftBraceRange.location != NSNotFound){
        NSRange rightBraceRange = [textString rangeOfString:@"}" options:NSCaseInsensitiveSearch range:NSMakeRange(leftBraceRange.location + leftBraceRange.length, end - leftBraceRange.location - leftBraceRange.length)];
        if(rightBraceRange.location != NSNotFound){
            NSInteger findStart = leftBraceRange.location + leftBraceRange.length;
            while(findStart < rightBraceRange.location){
                NSRange semicolonRange = [textString rangeOfString:@";" options:NSCaseInsensitiveSearch range:NSMakeRange(findStart , rightBraceRange.location -findStart)];
                if(semicolonRange.location != NSNotFound){
                    NSRange varRange = [textString rangeOfString:@"*" options:NSCaseInsensitiveSearch range:NSMakeRange(findStart, semicolonRange.location - findStart)];
                    if(varRange.location != NSNotFound){
                        NSString *var = [textString substringWithRange:NSMakeRange(varRange.location + varRange.length, semicolonRange.location - varRange.location - varRange.length)];
                        [varArray addObject:[var stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                    }else{
                        NSRange idRange = [textString rangeOfString:@"id " options:NSCaseInsensitiveSearch range:NSMakeRange(findStart, semicolonRange.location - findStart)];
                        if(idRange.location != NSNotFound){
                            NSString *var = [textString substringWithRange:NSMakeRange(idRange.location + idRange.length, semicolonRange.location - idRange.location - idRange.length)];
                            [varArray addObject:[var stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                        }
                    }
                    findStart = semicolonRange.location + semicolonRange.length;
                    continue;
                }
                break;
            }
        }
    }
    return varArray;
}

+(NSArray*)findPropertyArray:(NSString*)textString location:(NSInteger)findStart end:(NSInteger)end
{
    NSMutableArray *propertyArray = [NSMutableArray array];
    while (findStart < end) {
        NSRange propertyRange = [textString rangeOfString:@"@property" options:NSCaseInsensitiveSearch range:NSMakeRange(findStart, end - findStart)];
        if(propertyRange.location != NSNotFound){
            NSRange semicolonRange = [textString rangeOfString:@";" options:NSCaseInsensitiveSearch range:NSMakeRange(propertyRange.location + propertyRange.length , end - propertyRange.location - propertyRange.length)];
            if(semicolonRange.location != NSNotFound){
                NSRange typeLeftRange = [textString rangeOfString:@"(" options:NSCaseInsensitiveSearch range:NSMakeRange(propertyRange.location + propertyRange.length, semicolonRange.location - propertyRange.location - propertyRange.length)];
                if(typeLeftRange.location != NSNotFound){
                    NSRange typeRightRange = [textString rangeOfString:@")" options:NSCaseInsensitiveSearch range:NSMakeRange(typeLeftRange.location + typeLeftRange.length, semicolonRange.location - typeLeftRange.location - typeLeftRange.length)];
                    if(typeRightRange.location != NSNotFound){
                        NSString *type = [textString substringWithRange:NSMakeRange(typeLeftRange.location, typeRightRange.location - typeLeftRange.location)];
                        if([type rangeOfString:@"strong" options:NSCaseInsensitiveSearch].location != NSNotFound || [type rangeOfString:@"retain" options:NSCaseInsensitiveSearch].location != NSNotFound || [type rangeOfString:@"copy" options:NSCaseInsensitiveSearch].location != NSNotFound){
                            NSRange varRange = [textString rangeOfString:@"*" options:NSCaseInsensitiveSearch range:NSMakeRange(typeRightRange.location, semicolonRange.location - typeRightRange.location)];
                            if(varRange.location != NSNotFound){
                                NSString *var = [textString substringWithRange:NSMakeRange(varRange.location + varRange.length, semicolonRange.location - varRange.location - varRange.length)];
                                [propertyArray addObject:[var stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                            }else{
                                NSRange idRange = [textString rangeOfString:@"id " options:NSCaseInsensitiveSearch range:NSMakeRange(typeRightRange.location, semicolonRange.location - typeRightRange.location)];
                                if(idRange.location != NSNotFound){
                                    NSString *var = [textString substringWithRange:NSMakeRange(idRange.location + idRange.length, semicolonRange.location - idRange.location - idRange.length)];
                                    [propertyArray addObject:[var stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                                }
                            }
                        }
                    }
                }
            }
            findStart = semicolonRange.location + semicolonRange.length;
            continue;
        }
        break;;
    }
    return propertyArray;
}

+(NSString*)generateDeallocCodeForPropertyArray:(NSArray*)propertyArray varArray:(NSArray*)varArray interfaceName:(NSString*)interfaceName
{
    if(propertyArray.count > 0  || varArray.count > 0){
        NSMutableString *code = [NSMutableString stringWithFormat:@"/**\n * Interface %@ dealloc\n */\n-(void)dealloc\n{\n#if !__has_feature(objc_arc)",interfaceName];
        if(varArray.count > 0){
            [code appendString:@"\n\t//This is member variables release, please check !!!!!!"];
            for(NSString *var in varArray){
                [code appendFormat:@"\n\t[%@ release];\n\t%@ = nil;",var,var];
            }
            [code appendString:@"\n"];
        }
        if(propertyArray.count > 0){
            [code appendString:@"\n\t//This is retain/strong/copy property release"];
            for(NSString *var in propertyArray){
                [code appendFormat:@"\n\tself.%@ = nil;",var];
            }
            [code appendString:@"\n"];
        }
        [code appendString:@"\n\t[super dealloc];\n"];
        [code appendString:@"#endif\n}"];
        return code;
    }
    return nil;
}


@end
