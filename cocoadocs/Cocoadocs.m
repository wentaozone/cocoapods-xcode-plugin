//
//  Cocoadocs.m
//
//  Copyright (c) 2013 Delisa Mason. http://delisa.me
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

#import "Cocoadocs.h"

static NSString *RELATIVE_DOCSET_PATH  = @"/Library/Developer/Shared/Documentation/DocSets/";
static NSString *DOCSET_ARCHIVE_FORMAT = @"http://cocoadocs.org/docsets/%@/docset.xar";
static NSString *XAR_EXECUTABLE = @"/usr/bin/xar";

@implementation Cocoadocs

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] init];
    });
}

+ (NSString *)docsetInstallPath {
    return [NSString pathWithComponents:@[NSHomeDirectory(), RELATIVE_DOCSET_PATH]];
}

- (id)init
{
    if (self = [super init]) {
        NSMenuItem *topMenuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
        if (topMenuItem) {
            [[topMenuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *installDocsItem = [[NSMenuItem alloc] initWithTitle:@"Install DocSets for Pods" action:@selector(installOrUpdateDocSetsForPods) keyEquivalent:@""];
            [installDocsItem setTarget:self];
            [[topMenuItem submenu] addItem:installDocsItem];
        }
    }
    return self;
}

- (void)installOrUpdateDocSetsForPods {
    for (NSString *podName in [self installedPodNamesInWorkspace]) {
        NSURL *docsetURL = [NSURL URLWithString:[NSString stringWithFormat:DOCSET_ARCHIVE_FORMAT, podName]];
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:docsetURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *xarData, NSError *connectionError) {
            if (xarData) {
                NSString *tmpFilePath = [NSString pathWithComponents:@[NSTemporaryDirectory(), [NSString stringWithFormat:@"%@.xar",podName]]];
                [xarData writeToFile:tmpFilePath atomically:YES];
                [self extractPath:tmpFilePath];
            }
        }];
    }
}

#pragma mark - Private

- (void)extractPath:(NSString *)path {
    NSTask *task = [NSTask new];

    task.currentDirectoryPath = NSTemporaryDirectory();
    task.launchPath = XAR_EXECUTABLE;
    task.arguments  = @[@"-xf", path, @"-C", [Cocoadocs docsetInstallPath]];
    @try {
        [task launch];
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to extract file: %@", exception);
    }
}

- (NSArray *)installedPodNamesInWorkspace {
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

- (id)workspaceForKeyWindow {
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];

    for (id controller in workspaceWindowControllers) {
        if ([[controller valueForKey:@"window"] isKeyWindow]) {
            return [controller valueForKey:@"_workspace"];
            
        }
    }
    return nil;
}

@end
