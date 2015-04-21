//
//  FileSearchHelper.h
//  VCXcodePlugin
//
//  Created by Vic Zhang on 15/4/21.
//  Copyright (c) 2015 ___Company Name___. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileSearchHelper : NSObject

+(NSArray*)searchWorkspaceForFiles:(NSArray*)fileNameArray;

@end
