//
//  FileSearchHelper.m
//  VCXcodePlugin
//
//  Created by Vic Zhang on 15/4/21.
//  Copyright (c) 2015 ___Company Name___. All rights reserved.
//

#import "FileSearchHelper.h"
#import <Cocoa/Cocoa.h>

static NSMutableArray *searchFileArray = nil;

@implementation FileSearchHelper

+(NSString*)currentWorkspaceFolder
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    id workSpace;
    for (id controller in workspaceWindowControllers) {
        if ([[controller valueForKey:@"window"] isEqual:[NSApp keyWindow]]) {
            workSpace = [controller valueForKey:@"_workspace"];
        }
    }
    id representingFilePath = [workSpace valueForKey:@"representingFilePath"];
    NSString *workspacePath =  [representingFilePath valueForKey:@"_pathString"];
    return [workspacePath stringByDeletingLastPathComponent];
}

+(NSArray*)searchWorkspaceForFiles:(NSArray*)fileNameArray
{
    NSString *currentWorkspaceFolder = [self currentWorkspaceFolder];
    NSMutableArray *textStringArray = [NSMutableArray array];
    @synchronized(self){
        if(searchFileArray == nil){
            searchFileArray = [NSMutableArray array];
        }
        [searchFileArray removeAllObjects];
        [self searchFolder:currentWorkspaceFolder forFiles:fileNameArray];
        if([searchFileArray count] > 0){
            for(NSString *path in searchFileArray){
                NSError *error = nil;
                NSString *content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
                if(error != nil){
                    break;
                }
                if([content length] > 0){
                    [textStringArray addObject:content];
                }
            }
        }
    }
    return textStringArray;
    
}
+ (void)searchFolder:(NSString *)folder forFiles:(NSArray*)files
{
    NSFileManager * fileManger = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManger fileExistsAtPath:folder isDirectory:&isDir];
    if (isExist && isDir) {
        NSArray * dirArray = [fileManger contentsOfDirectoryAtPath:folder error:nil];
        NSString * subPath = nil;
        for (NSString * fileName in dirArray) {
            subPath  = [folder stringByAppendingPathComponent:fileName];
            BOOL issubDir = NO;
            [fileManger fileExistsAtPath:subPath isDirectory:&issubDir];
            if(!issubDir && [self isFileName:fileName hitArray:files]){
                [searchFileArray addObject:subPath];
            }
            else if(issubDir){
                [self searchFolder:subPath forFiles:files];
            }
        }
    }
}
+(BOOL)isFileName:(NSString*)fileName hitArray:(NSArray*)fileNameArray
{
    for(NSString *file in fileNameArray){
        if([file isEqualToString:fileName]){
            return YES;
        }
    }
    return NO;
}

@end


