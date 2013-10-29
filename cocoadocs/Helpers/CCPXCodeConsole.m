/*
 * #%L
 * xcode-maven-plugin
 * %%
 * Copyright (C) 2012 SAP AG
 * %%
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * #L%
 */

#import "CCPXCodeConsole.h"

@interface CCPXCodeConsole ()

@property (retain) NSTextView *console;

@end


@implementation CCPXCodeConsole

- (id)init
{
    if (self = [super init])
    {
        self.console = [self findConsoleAndActivate];
    }
    
    return self;
}

- (void)appendText:(NSString *)text
{
	[self appendText:text color:NSColor.whiteColor];
}

- (void)appendText:(NSString *)text color:(NSColor *)color
{
	if (text == nil)
	{
		return;
	}
    
	NSMutableDictionary *attributes = [@{ NSForegroundColorAttributeName: color } mutableCopy];
	NSFont *font = [NSFont fontWithName:@"Menlo Regular" size:11];
	if (font)
	{
		attributes[NSFontAttributeName] = font;
	}
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:text attributes:attributes];
	NSRange theEnd = NSMakeRange(self.console.string.length, 0);
	theEnd.location += as.string.length;
	if (NSMaxY(self.console.visibleRect) == NSMaxY(self.console.bounds))
	{
		[self.console.textStorage appendAttributedString:as];
		[self.console scrollRangeToVisible:theEnd];
	}
	else
	{
		[self.console.textStorage appendAttributedString:as];
	}
}

#pragma mark - Console Detection

- (NSTextView *)findConsoleAndActivate
{
	Class consoleTextViewClass = NSClassFromString(@"IDEConsoleTextView");
	NSTextView *console = (NSTextView *)[self findView:consoleTextViewClass inView:NSApplication.sharedApplication.mainWindow.contentView];
    
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
    
    NSRange range; range.location = 0; range.length = console.textStorage.length;
    [console.textStorage deleteCharactersInRange:range];
    
	return console;
}

- (NSView *)findView:(Class)consoleClass inView:(NSView *)view
{
	if ([view isKindOfClass:consoleClass])
	{
		return view;
	}
    
	for (NSView *v in view.subviews)
	{
		NSView *result = [self findView:consoleClass inView:v];
		if (result)
		{
			return result;
		}
	}
	return nil;
}

@end
