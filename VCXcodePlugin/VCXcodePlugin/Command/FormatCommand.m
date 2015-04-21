//
//  FormatCommand.m
//  VCXcodePlugin
//
//  Created by Vic Zhang on 15/4/16.
//  Copyright (c) 2015 ___Company Name___. All rights reserved.
//

#import "FormatCommand.h"

@interface FormatCommand()
@end

@implementation FormatCommand

+(NSString*)formatString:(NSString*)textString
{
    NSMutableString *resultString = [NSMutableString string];
    NSInteger i,j;
    for(i = 0; i< textString.length - 2; i++){
        if([[textString substringWithRange:NSMakeRange(i, 2)] isEqualToString:@"@\""] && ![[self class] filterStringWithLocation:i textString:textString]){
            BOOL isFindEnd = NO;
            for(j= i + 2;j< textString.length;j++){
                if([[textString substringWithRange:NSMakeRange(j,1)] isEqualToString:@"\""] && ![[textString substringWithRange:NSMakeRange(j-1,1)] isEqualToString:@"\\"]){
                    NSString *findString = [textString substringWithRange:NSMakeRange(i, j-i+1)];
                    if([[self class] isContainChineseString:findString]){
                        NSString *replaceString = [NSString stringWithFormat:@"NSLocalizedString(%@,nil)",findString];
                        [resultString appendString:replaceString];
                    }else{
                        [resultString appendString:findString];
                    }
                    i = j;
                    isFindEnd = YES;
                    break;
                }
            }
            if(isFindEnd){
                continue;
            }else{
                [resultString appendString:[textString substringWithRange:NSMakeRange(i,textString.length - i)]];
                break;
            }
        }else{
            [resultString appendString:[textString substringWithRange:NSMakeRange(i,1)]];
            continue;
        }
    }
    if(i < textString.length){
        [resultString appendString:[textString substringFromIndex:i]];
    }
    return resultString;
}

+(BOOL)filterStringWithLocation:(NSInteger)location textString:(NSString*)textString
{
    NSArray *filterKeyWord = [NSArray arrayWithObjects:@"NSLog(",@"NSLocalizedString(",@"NSLocalizedStringFromTable(",@"NSLocalizedStringFromTableInBundle(",@"NSLocalizedStringWithDefaultValue(",@"objectForKey:",@"forKey:",@"forKeyPath:", nil];
    for(NSString *key in filterKeyWord){
        NSInteger start = location - key.length;
        if(start >=0 && [[textString substringWithRange:NSMakeRange(start, key.length)] caseInsensitiveCompare:key] == NSOrderedSame){
            return YES;
        }
    }
    return NO;
}

+(BOOL)isContainChineseString:(NSString*)str
{
    NSPredicate *textPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".*[\u4e00-\u9fa5].*"];
    if ([textPre evaluateWithObject:str]) {
        return YES;
    }
    return NO;
}

-(BOOL)isNoMeanString:(NSString*)str
{
    if([str caseInsensitiveCompare:@"@\"%d\""] == NSOrderedSame ||
       [str caseInsensitiveCompare:@"@\"%f\""] == NSOrderedSame||
       [str caseInsensitiveCompare:@"@\"%@\""] == NSOrderedSame ||
       [str caseInsensitiveCompare:@"@\"%lld\""] == NSOrderedSame ||
       [str caseInsensitiveCompare:@"@\"%ld\""] == NSOrderedSame ||
       [str caseInsensitiveCompare:@"@\"\""] == NSOrderedSame)
    {
        return YES;
    }
    return NO;
}


@end
