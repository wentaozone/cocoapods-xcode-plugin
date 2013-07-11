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

@interface NSObject (IDEKit)

- (void)insertText:(NSString *)text;
- (void)insertNewline:(NSString *)wat;
- (void)clearConsoleItems;
- (void)setLogMode:(NSUInteger)logMode;
- (NSUInteger)logMode;
@end

@implementation CCPShellHandler

+ (void)runShellCommand:(NSString *)command withArgs:(NSArray *)args directory:(NSString *)directory completion:(void(^)(NSString *stdOut, NSString *stdErr))completion {
    __block NSMutableData *taskOutput = [NSMutableData new];
    __block NSMutableData *taskError  = [NSMutableData new];

    NSTask *task = [NSTask new];

    task.currentDirectoryPath = directory;
    task.launchPath = command;
    task.arguments  = args;

    task.standardOutput = [NSPipe pipe];
    task.standardError  = [NSPipe pipe];

    id window = [[NSApplication sharedApplication] keyWindow];
    NSView *contentView = [window valueForKey:@"contentView"];
    __block NSView *console = [self consoleViewInMainView:contentView];
    [console clearConsoleItems];
    console.logMode = 1;

    [[task.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSData *data = [file availableData];
        [taskOutput appendData:data];
        [self writeData:data toConsole:console];
    }];

    [[task.standardError fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSData *data = [file availableData];
        [taskError appendData:data];
        [self writeData:data toConsole:console];
    }];

    [task setTerminationHandler:^(NSTask *t) {
        [t.standardOutput fileHandleForReading].readabilityHandler = nil;
        [t.standardError fileHandleForReading].readabilityHandler  = nil;
        NSString *output = [[NSString alloc] initWithData:taskOutput encoding:NSUTF8StringEncoding];
        NSString *error  = [[NSString alloc] initWithData:taskError encoding:NSUTF8StringEncoding];
        NSLog(@"Shell command output: %@", output);
        NSLog(@"Shell command error: %@", error);
        if (completion) completion(output, error);
    }];

    @try {
        [task launch];
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to launch: %@", exception);
    }
}

+ (void)writeData:(NSData *)data toConsole:(NSView *)console {
    if ([data length] > 0) {
        @try {
            [console insertText:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            [console insertNewline:@""];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception occurred while piping to console: %@", [exception description]);
        }
    }
}

+ (NSView *)consoleViewInMainView:(NSView *)mainView
{
    for (NSView *childView in mainView.subviews) {
        if ([childView isKindOfClass:NSClassFromString(@"IDEConsoleTextView")]) {
            return childView;
        } else {
            NSView *view = [self consoleViewInMainView:childView];
            if ([view isKindOfClass:NSClassFromString(@"IDEConsoleTextView")]) {
                return view;
            }
        }
    }
    return nil;
}

@end
