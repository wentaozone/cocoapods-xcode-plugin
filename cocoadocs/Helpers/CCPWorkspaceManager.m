//
//  CCPWorkspaceManager.m
//  CocoaPods
//
//  Created by Delisa Mason on 7/11/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

#import "CCPWorkspaceManager.h"

static NSString *PODFILE = @"Podfile";

@implementation CCPWorkspaceManager

+ (NSArray *)installedPodNamesInCurrentWorkspace {
    NSMutableArray *names = [NSMutableArray new];
    id workspace = [self workspaceForKeyWindow];

    id contextManager = [workspace valueForKey:@"_runContextManager"];
    for (id scheme in [contextManager valueForKey:@"runContexts"]) {
        NSString *schemeName = [scheme valueForKey:@"name"];
        if ([schemeName hasPrefix:@"Pods-"]) {
            [names addObject:[schemeName stringByReplacingOccurrencesOfString:@"Pods-" withString:@""]];
        }
    }
    return names;
}

+ (NSString *)currentWorkspacePodfilePath {
    return [[self currentWorkspaceDirectoryPath] stringByAppendingPathComponent:@"Podfile"];
}

+ (NSString *)currentWorkspaceDirectoryPath {
    id workspace = [self workspaceForKeyWindow];
    NSString *workspacePath = [[workspace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
    return [workspacePath stringByDeletingLastPathComponent];
}

+ (BOOL)currentWorkspaceHasPodfile {
    return [self fileNameExistsInCurrentWorkspace:PODFILE];
}

+ (BOOL)fileNameExistsInCurrentWorkspace:(NSString *)fileName {
    NSString *filePath = [[self currentWorkspaceDirectoryPath] stringByAppendingPathComponent:fileName];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

#pragma mark - Private

+ (id)workspaceForKeyWindow {
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];

    for (id controller in workspaceWindowControllers) {
        if ([[controller valueForKey:@"window"] valueForKey:@"isKeyWindow"]) {
            return [controller valueForKey:@"_workspace"];

        }
    }
    return nil;
}

@end
