//
//  VCXcodePlugin.m
//  VCXcodePlugin
//
//  Created by Vic Zhang on 15/4/15.
//  Copyright (c) 2015 ___Company Name___. All rights reserved.
//

#import "VCXcodePlugin.h"
#import "FormatCommand.h"
#import "DeallocCommond.h"
#import "KeyboradHelper.h"

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

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        if([self isCurrentLineIsOnlyText:@"@format" textView:text]){
            [self computeFormatCommnad:text];
            return;
        }
        if([self isCurrentLineIsOnlyText:@"@dealloc" textView:text]){
            [self computeDeallocCommnad:text];
            return;
        }
    }
}
-(BOOL)isCurrentLineIsOnlyText:(NSString*)text textView:(NSTextView*)textView
{
    NSString *string = [textView string];
    if([string length] == 0 || textView.selectedRange.location >= string.length){
        return NO;
    }
    NSRange leftRange = [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, textView.selectedRange.location)];
    NSRange rightRange = [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSCaseInsensitiveSearch range:NSMakeRange(textView.selectedRange.location, string.length - textView.selectedRange.location)];
    if(leftRange.location != NSNotFound && rightRange.location != NSNotFound && [[[string substringWithRange:NSMakeRange(leftRange.location, rightRange.location - leftRange.location)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:text]){
        return YES;
    }
    return NO;
}

-(BOOL)computeFormatCommnad:(NSTextView*)text
{
    NSString *formatCommand = @"@format";
    NSMutableString *textString = [NSMutableString stringWithFormat:@"%@",text.string];
    if([textString length] >0 && text.selectedRange.location >= formatCommand.length && [[textString substringWithRange:NSMakeRange(text.selectedRange.location - formatCommand.length, formatCommand.length)] isEqualToString:formatCommand]){
        NSRange usedRange = text.selectedRange;
        [textString replaceCharactersInRange:NSMakeRange(text.selectedRange.location - formatCommand.length, formatCommand.length) withString:@""];
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
        [textString replaceCharactersInRange:NSMakeRange(text.selectedRange.location - deallocCommand.length, deallocCommand.length) withString:@""];
        NSRange usedRange = NSMakeRange(text.selectedRange.location - deallocCommand.length, text.selectedRange.length);
        NSString *deallocString = [DeallocCommond deallocString:textString currentLocation:usedRange.location];
        NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
        NSString *originPBString = [pasteBoard stringForType:NSPasteboardTypeString];
        [pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pasteBoard setString:deallocString forType:NSStringPboardType];
        [[KeyboradHelper defaultKeyboradHelper] keyboardDidTap:kVK_Delete flags:kCGEventFlagMaskCommand doneBlock:nil];
        [[KeyboradHelper defaultKeyboradHelper] keyboardDidTap:kVK_ANSI_V flags:kCGEventFlagMaskCommand doneBlock:nil];
        [[KeyboradHelper defaultKeyboradHelper] keyboardDidTap:kVK_F20 flags:0 doneBlock:^NSEvent *(NSEvent *event) {
            if(event.keyCode == kVK_F20){
                [pasteBoard setString:originPBString forType:NSStringPboardType];
                text.selectedRange = NSMakeRange(usedRange.location + deallocString.length, 0);
                [[KeyboradHelper defaultKeyboradHelper] removeMoniter];
                return nil;
            }
            return event;
        }];
        return YES;
    }
    return NO;
}

@end


