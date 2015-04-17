//
//  VCXcodePlugin.m
//  VCXcodePlugin
//
//  Created by Vic Zhang on 15/4/15.
//  Copyright (c) 2015年 ___Company Name___. All rights reserved.
//

#import "VCXcodePlugin.h"
#import "FormatCommand.h"
#import "DeallocCommond.h"

@implementation VCXcodePlugin

+ (void) pluginDidLoad: (NSBundle*) plugin
{
    NSLog(@"VCXcodePlugin load");
    [self shared];
}

+(id) shared
{
    static dispatch_once_t once;
    static id instance = nil;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void) applicationDidFinishLaunching: (NSNotification*) noti
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:NSTextDidChangeNotification
                                               object:nil];
}

-(void)textDidChange:(NSNotification*)notification
{
    if([notification.object isKindOfClass:[NSTextView class]]){
        NSTextView *text = notification.object;
        if([self computeFormatCommnad:text]){
            return;
        }
        if([self computeDeallocCommnad:text]){
            return;
        }
    }
}

-(BOOL)computeFormatCommnad:(NSTextView*)text
{
    NSString *formatCommand = @"@format";
    NSMutableString *textString = [NSMutableString stringWithFormat:@"%@",text.string];
    if([textString length] >0 && text.selectedRange.location >= formatCommand.length && [[textString substringWithRange:NSMakeRange(text.selectedRange.location - formatCommand.length, formatCommand.length)] isEqualToString:formatCommand]){
        NSRange usedRange = text.selectedRange;
        //先把@format去掉
        [textString replaceCharactersInRange:NSMakeRange(text.selectedRange.location - formatCommand.length, formatCommand.length) withString:@""];
        //取前面30个字符串，接着还原这个位置
        NSInteger length = 30;
        NSInteger start = (NSInteger)usedRange.location - length - formatCommand.length;
        if(start <= 0){
            length += start;
            start = 0;
        }
        NSString *positionString = [textString substringWithRange:NSMakeRange(start, length)];
        NSString *formatSring = [FormatCommand formatString:textString];
        text.string = formatSring;
        NSRange range =  [formatSring rangeOfString:positionString];
        if(range.location != NSNotFound){
            text.selectedRange = NSMakeRange(range.location + range.length, usedRange.length);
        }else{
            text.selectedRange = usedRange;
        }
        return YES;
    }
    return NO;
}

-(BOOL)computeDeallocCommnad:(NSTextView*)text
{
    NSString *deallocCommand = @"@dealloc";
    NSMutableString *textString = [NSMutableString stringWithFormat:@"%@",text.string];
    if([textString length] >0 && text.selectedRange.location >= deallocCommand.length && [[textString substringWithRange:NSMakeRange(text.selectedRange.location - deallocCommand.length, deallocCommand.length)] isEqualToString:deallocCommand]){
        //先把@dealloc去掉
        [textString replaceCharactersInRange:NSMakeRange(text.selectedRange.location - deallocCommand.length, deallocCommand.length) withString:@""];
        NSRange usedRange = NSMakeRange(text.selectedRange.location - deallocCommand.length, text.selectedRange.length);
        NSString *deallocString = [DeallocCommond deallocString:textString];
        if([deallocString length] > 0){
            if(textString.length > usedRange.location){
                [textString insertString:deallocString atIndex:usedRange.location];
            }else{
                [textString appendString:deallocString];
            }
            text.string = textString;
            text.selectedRange = usedRange;
        }
        return YES;
    }
    return NO;
}

@end


