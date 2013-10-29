//
//  CCPShellHandler.m
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

#import "CCPShellHandler.h"

#import "CCPRunOperation.h"
#import "CCPXCodeConsole.h"

@implementation CCPShellHandler

+ (void)runShellCommand:(NSString *)command withArgs:(NSArray *)args directory:(NSString *)directory completion:(void (^)(NSTask *t))completion
{
//    __block NSMutableData *taskOutput = [NSMutableData new];
//    __block NSMutableData *taskError  = [NSMutableData new];
    
	NSTask *task = [NSTask new];
    
	task.currentDirectoryPath = directory;
	task.launchPath = command;
	task.arguments  = args;
    
	CCPRunOperation *operation = [[CCPRunOperation alloc] initWithTask:task];
    
	CCPXCodeConsole *console = [[CCPXCodeConsole alloc] initWithConsole:[CCPShellHandler findConsoleAndActivate]];
	operation.xcodeConsole = console;
    
    [operation start];
//
//    task.standardOutput = [NSPipe pipe];
//    task.standardError  = [NSPipe pipe];
//
//    [[task.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
//        [taskOutput appendData:[file availableData]];
//    }];
//
//    [[task.standardError fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
//        [taskError appendData:[file availableData]];
//    }];
//
//    [task setTerminationHandler:^(NSTask *t) {
//        [t.standardOutput fileHandleForReading].readabilityHandler = nil;
//        [t.standardError fileHandleForReading].readabilityHandler  = nil;
//        NSString *output = [[NSString alloc] initWithData:taskOutput encoding:NSUTF8StringEncoding];
//        NSString *error = [[NSString alloc] initWithData:taskError encoding:NSUTF8StringEncoding];
//        NSLog(@"Shell command output: %@", output);
//        NSLog(@"Shell command error: %@", error);
//        if (completion) completion(t);
//    }];
//
//    @try {
//        [task launch];
//    }
//    @catch (NSException *exception) {
//        NSLog(@"Failed to launch: %@", exception);
//    }
}

+ (NSTextView *)findConsoleAndActivate
{
	Class consoleTextViewClass = NSClassFromString(@"IDEConsoleTextView");
	NSTextView *console = (NSTextView *)[CCPShellHandler findView:consoleTextViewClass inView:NSApplication.sharedApplication.mainWindow.contentView];
    
	if (console)
	{
		NSWindow *window = NSApplication.sharedApplication.keyWindow;
		if ([window isKindOfClass:NSClassFromString(@"IDEWorkspaceWindow")])
		{
			if ([window.windowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")])
			{
				id editorArea = [window.windowController valueForKey:@"editorArea"];
				[editorArea performSelector:@selector(activateConsole:) withObject:self];
			}
		}
	}
    
	return console;
}

+ (NSView *)findView:(Class)consoleClass inView:(NSView *)view
{
	if ([view isKindOfClass:consoleClass])
	{
		return view;
	}
    
	for (NSView *v in view.subviews)
	{
		NSView *result = [CCPShellHandler findView:consoleClass inView:v];
		if (result)
		{
			return result;
		}
	}
	return nil;
}

@end
