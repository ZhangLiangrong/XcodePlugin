//
//  KeyboradHelper.m
//  VCXcodePlugin
//
//  Created by Vic Zhang on 4/22/15.
//  Copyright (c) 2015 ___Company Name___. All rights reserved.
//

#import "KeyboradHelper.h"

@interface KeyboradHelper()
{
    CGEventSourceRef _eventSourceRef;
}
@property(nonatomic,copy)DoneBlock doneBlock;
@property(nonatomic,strong)NSEvent *event;

@end

@implementation KeyboradHelper

+(id)defaultKeyboradHelper
{
    static KeyboradHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[KeyboradHelper alloc] init];
    });
    return instance;
    
}

-(void)addMoniter
{
    if(self.event == nil){
        self.event = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^NSEvent *(NSEvent *event) {
            if(self.doneBlock){
                return self.doneBlock(event);
            }
            return event;
        }];
    }
}

-(void)removeMoniter
{
    if(self.event){
        [NSEvent removeMonitor:self.event];
    }
    self.event = nil;
}

-(void)dealloc
{
    if(_eventSourceRef){
        CFRelease(_eventSourceRef);
    }
    self.doneBlock = nil;
}

-(instancetype)init
{
    self = [super init];
    if(self){
        _eventSourceRef = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    }
    return self;
}

-(void)keyboardDidTap:(CGKeyCode)keyCode flags:(CGEventFlags)flags doneBlock:(DoneBlock)block
{
    [self addMoniter];
    self.doneBlock = block;
    CGEventRef event;
    event = CGEventCreateKeyboardEvent(_eventSourceRef, keyCode, YES);
    CGEventSetFlags(event, flags);
    CGEventPost(kCGHIDEventTap, event);
    CFRelease(event);
    
    event = CGEventCreateKeyboardEvent(_eventSourceRef, keyCode, NO);
    CGEventSetFlags(event, flags);
    CGEventPost(kCGHIDEventTap, event);
    CFRelease(event);
    
}

@end
