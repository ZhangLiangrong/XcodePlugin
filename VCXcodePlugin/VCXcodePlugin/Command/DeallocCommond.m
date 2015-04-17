//
//  DeallocCommond.m
//  VCXcodePlugin
//
//  Created by Vic Zhang on 15/4/11.
//  Copyright (c) 2015年 ___Company Name___. All rights reserved.
//

#import "DeallocCommond.h"

@implementation DeallocCommond

+(NSString*)deallocString:(NSString*)textString
{
    NSMutableString *resultString = [NSMutableString string];
    NSMutableArray *varArray = [NSMutableArray array];
    NSInteger location = 0;
    while (location < textString.length) {
        NSRange interfaceRange = [textString rangeOfString:@"@interface" options:NSCaseInsensitiveSearch range:NSMakeRange(location, textString.length - location)];
        NSRange endRange = [textString rangeOfString:@"@end" options:NSCaseInsensitiveSearch range:NSMakeRange(location, textString.length - location)];
        if(interfaceRange.location != NSNotFound && endRange.location != NSNotFound && endRange.location > interfaceRange.location + interfaceRange.length){
            [varArray removeAllObjects];
            NSInteger findStart = interfaceRange.location + interfaceRange.length + 1;
            while (findStart < endRange.location) {
                NSRange propertyRange = [textString rangeOfString:@"@property" options:NSCaseInsensitiveSearch range:NSMakeRange(findStart, endRange.location - findStart)];
                if(propertyRange.location != NSNotFound){
                    NSRange semicolonRange = [textString rangeOfString:@";" options:NSCaseInsensitiveSearch range:NSMakeRange(propertyRange.location + propertyRange.length , endRange.location - propertyRange.location - propertyRange.length)];
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
                                        [varArray addObject:[var stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
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
            if([varArray count] > 0){
                NSString *newCode = [self generateDeallocCodeForArray:varArray];
                [resultString appendString:newCode];
            }
        }
        location = endRange.location + endRange.length;
    }
    return resultString;
}

+(NSString*)generateDeallocCodeForArray:(NSArray*)array
{
    NSMutableString *code = [NSMutableString stringWithFormat:@"-(void)dealloc\n{"];
    for(NSString *var in array){
        [code appendFormat:@"\n\t[_%@ release];\n\t_%@ = nil;",var,var];
    }
    [code appendString:@"\n\t[super dealloc];\n}\n"];
    return code;
}


@end
