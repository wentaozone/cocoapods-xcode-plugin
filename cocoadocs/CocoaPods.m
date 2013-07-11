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

#import "CocoaPods.h"
#import "CCPShellHandler.h"
#import "CCPWorkspaceManager.h"
#import "CCPDocumentationManager.h"

static NSString *DMMCocoaPodsIntegrateWithDocsKey = @"DMMCocoaPodsIntegrateWithDocs";
static NSString *DOCSET_ARCHIVE_FORMAT = @"http://cocoadocs.org/docsets/%@/docset.xar";
static NSString *XAR_EXECUTABLE = @"/usr/bin/xar";


@interface CocoaPods ()
@property (nonatomic, strong) NSMenuItem *installPodsItem;
@property (nonatomic, strong) NSMenuItem *editPodfileItem;
@property (nonatomic, strong) NSMenuItem *installDocsItem;
@property (nonatomic, strong) NSMenuItem *createPodfileItem;

@property (nonatomic, strong) NSBundle *bundle;
@end


@implementation CocoaPods

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] initWithBundle:plugin];
    });
}

- (id)initWithBundle:(NSBundle *)plugin {
    if (self = [super init]) {
        _bundle = plugin;
        [self addMenuItems];
    }
    return self;
}

#pragma mark - Menu

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem isEqual:self.installPodsItem] || [menuItem isEqual:self.editPodfileItem])
        return [CCPWorkspaceManager currentWorkspaceHasPodfile];

    else if ([menuItem isEqual:self.createPodfileItem])
        return [CCPWorkspaceManager currentWorkspaceDirectoryPath] != nil;

    return YES;
}

- (void)addMenuItems {
    NSMenuItem *topMenuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
    if (topMenuItem) {
        NSMenuItem *cocoaPodsMenu = [[NSMenuItem alloc] initWithTitle:@"CocoaPods" action:nil keyEquivalent:@""];
        cocoaPodsMenu.submenu = [[NSMenu alloc] initWithTitle:@"CocoaPods"];
        
        self.installDocsItem = [[NSMenuItem alloc] initWithTitle:@"Install Docs during Integration"
                                                          action:@selector(toggleInstallDocsForPods)
                                                   keyEquivalent:@""];
        self.installDocsItem.state = [self shouldInstallDocsForPods] ? NSOnState : NSOffState;
        
        self.installPodsItem = [[NSMenuItem alloc] initWithTitle:@"Install Pods in Podfile"
                                                          action:@selector(integratePods)
                                                   keyEquivalent:@""];
        
        self.editPodfileItem = [[NSMenuItem alloc] initWithTitle:@"Edit Podfile"
                                                          action:@selector(openPodfileForEditing)
                                                   keyEquivalent:@""];

        self.createPodfileItem = [[NSMenuItem alloc] initWithTitle:@"Create Podfile"
                                                            action:@selector(createPodfile)
                                                     keyEquivalent:@""];
        
        NSMenuItem *updateCPodsItem = [[NSMenuItem alloc] initWithTitle:@"Install/Update CocoaPods"
                                                                 action:@selector(installCocoaPods)
                                                          keyEquivalent:@""];
        
        [self.installDocsItem setTarget:self];
        [self.installPodsItem setTarget:self];
        [updateCPodsItem setTarget:self];
        [self.editPodfileItem setTarget:self];
        [self.createPodfileItem setTarget:self];

        [[cocoaPodsMenu submenu] addItem:self.createPodfileItem];
        [[cocoaPodsMenu submenu] addItem:self.installPodsItem];
        [[cocoaPodsMenu submenu] addItem:self.installDocsItem];
        [[cocoaPodsMenu submenu] addItem:[NSMenuItem separatorItem]];
        [[cocoaPodsMenu submenu] addItem:self.editPodfileItem];
        [[cocoaPodsMenu submenu] addItem:updateCPodsItem];
        [[topMenuItem submenu] insertItem:cocoaPodsMenu atIndex:[topMenuItem.submenu indexOfItemWithTitle:@"Build For"]];
    }
}

#pragma mark - Menu Actions

- (void)toggleInstallDocsForPods {
    [self setShouldInstallDocsForPods:![self shouldInstallDocsForPods]];
}

- (void)createPodfile {
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:[self.bundle pathForResource:@"DefaultPodfile" ofType:@""] toPath:[CCPWorkspaceManager currentWorkspacePodfilePath] error:&error];
    if (!error) [self openPodfileForEditing];
    else [[NSAlert alertWithError:error] runModal];
}

- (void)openPodfileForEditing {
    if ([CCPWorkspaceManager currentWorkspaceHasPodfile]) {
        [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication]
                                                         openFile:[CCPWorkspaceManager currentWorkspacePodfilePath]];
    }
}

- (void)integratePods {
    [CCPShellHandler runShellCommand:@"/usr/bin/pod"
                            withArgs:@[@"install"]
                           directory:[CCPWorkspaceManager currentWorkspaceDirectoryPath]
                          completion:^(NSTask *t) {
        if ([self shouldInstallDocsForPods]) {
            [self installOrUpdateDocSetsForPods];
        }
    }];
}

- (void)installCocoaPods {
    [CCPShellHandler runShellCommand:@"/usr/bin/gem"
                            withArgs:@[@"install", @"cocoapods"]
                           directory:[CCPWorkspaceManager currentWorkspaceDirectoryPath]
                          completion:nil];
}

- (void)installOrUpdateDocSetsForPods {
    for (NSString *podName in [CCPWorkspaceManager installedPodNamesInCurrentWorkspace]) {
        NSURL *docsetURL = [NSURL URLWithString:[NSString stringWithFormat:DOCSET_ARCHIVE_FORMAT, podName]];
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:docsetURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *xarData, NSError *connectionError) {
            if (xarData) {
                NSString *tmpFilePath = [NSString pathWithComponents:@[NSTemporaryDirectory(), [NSString stringWithFormat:@"%@.xar",podName]]];
                [xarData writeToFile:tmpFilePath atomically:YES];
                [self extractAndInstallDocsAtPath:tmpFilePath];
            }
        }];
    }
}

- (void)extractAndInstallDocsAtPath:(NSString *)path {
    NSArray *arguments = @[@"-xf", path, @"-C", [CCPDocumentationManager docsetInstallPath]];
    [CCPShellHandler runShellCommand:XAR_EXECUTABLE
                            withArgs:arguments
                           directory:NSTemporaryDirectory()
                          completion:nil];
}

#pragma mark - Preferences

- (BOOL) shouldInstallDocsForPods {
    return [[NSUserDefaults standardUserDefaults] boolForKey:DMMCocoaPodsIntegrateWithDocsKey];
}

- (void) setShouldInstallDocsForPods:(BOOL)enabled {
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:DMMCocoaPodsIntegrateWithDocsKey];
    self.installDocsItem.state = enabled ? NSOnState : NSOffState;
}

@end
