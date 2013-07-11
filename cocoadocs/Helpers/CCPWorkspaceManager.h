//
//  CCPWorkspaceManager.h
//  CocoaPods
//
//  Created by Delisa Mason on 7/11/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCPWorkspaceManager : NSObject

+ (NSArray *)installedPodNamesInCurrentWorkspace;

+ (NSString *)currentWorkspaceDirectoryPath;
+ (NSString *)currentWorkspacePodfilePath;

+ (BOOL)currentWorkspaceHasPodfile;
+ (BOOL)fileNameExistsInCurrentWorkspace:(NSString *)fileName;

@end
