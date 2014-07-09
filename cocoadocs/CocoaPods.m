//
//  CocoaPods.m
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
#import "CCPProject.h"

static NSString *DMMCocoaPodsIntegrateWithDocsKey = @"DMMCocoaPodsIntegrateWithDocs";
static NSString *DOCSET_ARCHIVE_FORMAT = @"http://cocoadocs.org/docsets/%@/docset.xar";
static NSString *XAR_EXECUTABLE = @"/usr/bin/xar";
static NSString *POD_EXECUTABLE = @"pod";
static NSString *GEM_EXECUTABLE = @"gem";
static NSString *GEM_PATH_KEY = @"GEM_PATH_KEY";


@interface CocoaPods () <NSTextFieldDelegate>

@property (nonatomic, strong) NSMenuItem *installPodsItem;
@property (nonatomic, strong) NSMenuItem *outdatedPodsItem;
@property (nonatomic, strong) NSMenuItem *installDocsItem;

@property (nonatomic, strong) NSMenuItem *pathItem;
@property (nonatomic, strong) IBOutlet NSTextField *pathField;
@property (nonatomic, strong) IBOutlet NSView *pathView;

@property (nonatomic, strong) NSBundle *bundle;

@end


@implementation CocoaPods

+ (void)pluginDidLoad:(NSBundle *)plugin
{
	static id sharedPlugin = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	    sharedPlugin = [[self alloc] initWithBundle:plugin];
	});
}

- (id)initWithBundle:(NSBundle *)plugin
{
	if (self = [super init]) {
		_bundle = plugin;
        [self loadCustomGemPath];
		[self addMenuItems];
	}
	return self;
}

#pragma mark - Menu

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem isEqual:self.installPodsItem] || [menuItem isEqual:self.outdatedPodsItem]) {
        return [[CCPProject projectForKeyWindow] hasPodfile];
	}
    
	return YES;
}

- (void)addMenuItems
{
	NSMenuItem *topMenuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
	if (topMenuItem) {
		NSMenuItem *cocoaPodsMenu = [[NSMenuItem alloc] initWithTitle:@"CocoaPods" action:nil keyEquivalent:@""];
		cocoaPodsMenu.submenu = [[NSMenu alloc] initWithTitle:@"CocoaPods"];
        
		self.installDocsItem = [[NSMenuItem alloc] initWithTitle:@"Install Docs during Integration"
		                                                  action:@selector(toggleInstallDocsForPods)
		                                           keyEquivalent:@""];
		self.installDocsItem.state = [self shouldInstallDocsForPods] ? NSOnState : NSOffState;
        
		self.installPodsItem = [[NSMenuItem alloc] initWithTitle:@"Install Pods"
		                                                  action:@selector(integratePods)
		                                           keyEquivalent:@""];
        
		self.outdatedPodsItem = [[NSMenuItem alloc] initWithTitle:@"Check for Outdated Pods"
		                                                   action:@selector(checkForOutdatedPods)
		                                            keyEquivalent:@""];
        
		NSMenuItem *createPodfileItem = [[NSMenuItem alloc] initWithTitle:@"Create/Edit Podfile"
		                                                    action:@selector(createPodfile)
		                                             keyEquivalent:@""];
        
		NSMenuItem *createPodspecItem = [[NSMenuItem alloc] initWithTitle:@"Create/Edit Podspec"
		                                                    action:@selector(createPodspecFile)
		                                             keyEquivalent:@""];

        [[self bundle] loadNibNamed:@"PodPathView" owner:self topLevelObjects:nil];
        self.pathItem = [[NSMenuItem alloc] initWithTitle:@"Set POD_PATH"
                                                             action:@selector(setPATH)
                                                            keyEquivalent:@""];

        if ([self customGemPath].length > 0) {
            self.pathField.stringValue = [self customGemPath];
        }
        [self.pathItem setView:self.pathView];

        
		[self.installDocsItem setTarget:self];
		[self.installPodsItem setTarget:self];
		[self.outdatedPodsItem setTarget:self];
		[createPodfileItem setTarget:self];
		[createPodspecItem setTarget:self];
        [self.pathItem setTarget:self];
        
		[[cocoaPodsMenu submenu] addItem:self.installPodsItem];
		[[cocoaPodsMenu submenu] addItem:self.outdatedPodsItem];
		[[cocoaPodsMenu submenu] addItem:createPodfileItem];
        [[cocoaPodsMenu submenu] addItem:createPodspecItem];
		[[cocoaPodsMenu submenu] addItem:[NSMenuItem separatorItem]];
		[[cocoaPodsMenu submenu] addItem:self.installDocsItem];
        [[cocoaPodsMenu submenu] addItem:[NSMenuItem separatorItem]];
        [[cocoaPodsMenu submenu] addItem:self.pathItem];

		[[topMenuItem submenu] insertItem:cocoaPodsMenu atIndex:[topMenuItem.submenu indexOfItemWithTitle:@"Build For"]];
	}
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    NSLog(@"endEditing : %@" , fieldEditor.string);
    [self updateGemPath:fieldEditor.string];
    return YES;
}

- (void)updateGemPath:(NSString *)string {
    if (string.length == 0) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:GEM_PATH_KEY];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:string forKey:GEM_PATH_KEY];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self loadCustomGemPath];
}

- (void)loadCustomGemPath {
    NSString *newPath = [self customGemPath];
    if (newPath.length > 0) {
        char *oldPath = getenv("PATH");
        newPath = [NSString stringWithFormat:@"%@:%s", newPath, oldPath];
        setenv("PATH", [newPath UTF8String], 1);
    }
}

- (NSString *)customGemPath {
    return [[NSUserDefaults standardUserDefaults] objectForKey:GEM_PATH_KEY];
}

- (NSString *)gemPath {
    NSString *path = [self customGemPath];
    if (path.length == 0) {
        path = @"/usr/bin";
    }
    return path;
}

#pragma mark - Menu Actions

- (void)toggleInstallDocsForPods
{
	[self setShouldInstallDocsForPods:![self shouldInstallDocsForPods]];
}

- (void)createPodfile
{
    CCPProject *project = [CCPProject projectForKeyWindow];
    NSString *podFilePath = project.podfilePath;
    
	if (! [project hasPodfile]) {
		NSError *error = nil;
		[[NSFileManager defaultManager] copyItemAtPath:[self.bundle pathForResource:@"DefaultPodfile" ofType:@""] toPath:podFilePath error:&error];
		if (error) {
			[[NSAlert alertWithError:error] runModal];
		}
	}
    
    [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication]
                                                     openFile:podFilePath];
}

- (void)createPodspecFile
{
    CCPProject *project = [CCPProject projectForKeyWindow];
    NSString *podspecPath = project.podspecPath;
    
	if (! [project hasPodspecFile]) {
        NSString *podspecTemplate = [NSString stringWithContentsOfFile:[self.bundle pathForResource:@"DefaultPodspec" ofType:@""]
                                                              encoding:NSUTF8StringEncoding error:nil];
        
        [project createPodspecFromTemplate:podspecTemplate];
    }
    
    [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication]
                                                     openFile:podspecPath];
}

- (void)integratePods
{
	[CCPShellHandler runShellCommand:[[self gemPath]stringByAppendingPathComponent:POD_EXECUTABLE]
	                        withArgs:@[@"install"]
	                       directory:[CCPWorkspaceManager currentWorkspaceDirectoryPath]
	                      completion: ^(NSTask *t) {
                              if ([self shouldInstallDocsForPods])
                                  [self installOrUpdateDocSetsForPods];
                          }];
}

- (void)checkForOutdatedPods
{
	[CCPShellHandler runShellCommand:[[self gemPath]stringByAppendingPathComponent:POD_EXECUTABLE]
	                        withArgs:@[@"outdated"]
	                       directory:[CCPWorkspaceManager currentWorkspaceDirectoryPath]
	                      completion:nil];
}

- (void)installCocoaPods
{
	[CCPShellHandler runShellCommand:[[self gemPath]stringByAppendingPathComponent:GEM_EXECUTABLE]
	                        withArgs:@[@"install", @"cocoapods"]
	                       directory:[CCPWorkspaceManager currentWorkspaceDirectoryPath]
	                      completion:nil];
}

- (void)installOrUpdateDocSetsForPods
{
	for (NSString *podName in[CCPWorkspaceManager installedPodNamesInCurrentWorkspace]) {
		NSURL *docsetURL = [NSURL URLWithString:[NSString stringWithFormat:DOCSET_ARCHIVE_FORMAT, podName]];
		[NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:docsetURL] queue:[NSOperationQueue mainQueue] completionHandler: ^(NSURLResponse *response, NSData *xarData, NSError *connectionError) {
		    if (xarData) {
		        NSString *tmpFilePath = [NSString pathWithComponents:@[NSTemporaryDirectory(), [NSString stringWithFormat:@"%@.xar", podName]]];
		        [xarData writeToFile:tmpFilePath atomically:YES];
		        [self extractAndInstallDocsAtPath:tmpFilePath];
			}
		}];
	}
}

- (void)extractAndInstallDocsAtPath:(NSString *)path
{
	NSArray *arguments = @[@"-xf", path, @"-C", [CCPDocumentationManager docsetInstallPath]];
	[CCPShellHandler runShellCommand:XAR_EXECUTABLE
	                        withArgs:arguments
	                       directory:NSTemporaryDirectory()
	                      completion:nil];
}

#pragma mark - Preferences

- (BOOL)shouldInstallDocsForPods
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:DMMCocoaPodsIntegrateWithDocsKey];
}

- (void)setShouldInstallDocsForPods:(BOOL)enabled
{
	[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:DMMCocoaPodsIntegrateWithDocsKey];
	self.installDocsItem.state = enabled ? NSOnState : NSOffState;
}

@end
