//
//  KeyboradHelper.h
//  VCXcodePlugin
//
//  Created by Vic Zhang on 4/22/15.
//  Copyright (c) 2015 ___Company Name___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import <AppKit/AppKit.h>

typedef NSEvent* (^DoneBlock)(NSEvent *);

@interface KeyboradHelper : NSObject

+(id)defaultKeyboradHelper;

-(void)removeMoniter;

-(void)keyboardDidTap:(CGKeyCode)keyCode flags:(CGEventFlags)flags doneBlock:(DoneBlock)block;

@end
