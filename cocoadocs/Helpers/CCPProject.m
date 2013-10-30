//
//  CCPWorkspace.m
//  CocoaPods
//
//  Created by Flávio Caetano on 10/30/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

#import <objc/runtime.h>

#import "CCPProject.h"

#import "CCPWorkspaceManager.h"

@implementation CCPProject

- (id)initWithSchemeName:(NSString *)name
{
	if (self = [self init])
	{
		self.projectName = name;
        
		self.podspecPath = [[CCPWorkspaceManager currentWorkspaceDirectoryPath] stringByAppendingPathComponent:[name stringByAppendingString:@".podspec"]];
        
		self.directoryPath = [CCPWorkspaceManager currentWorkspaceDirectoryPath];
        
		NSString *infoPath = [self.directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@-Info.plist", self.projectName, self.projectName]];
		self.infoDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPath];
        
		self.podfilePath = [self.directoryPath stringByAppendingPathComponent:@"Podfile"];
	}
    
	return self;
}

- (BOOL)hasPodspecFile
{
	return [[NSFileManager defaultManager] fileExistsAtPath:self.podspecPath];
}

- (BOOL)hasPodfile
{
	return [[NSFileManager defaultManager] fileExistsAtPath:self.podfilePath];
}

- (void)createPodspecFromTemplate:(NSString *)_template
{
	NSMutableString *podspecFile    = _template.mutableCopy;
	NSRange range; range.location = 0;
    
	range.length = podspecFile.length;
	[podspecFile replaceOccurrencesOfString:@"<Project Name>"
	                             withString:self.projectName
	                                options:NSLiteralSearch
	                                  range:range];
    
	NSString *version = self.infoDictionary[@"CFBundleShortVersionString"];
	if (version)
	{
		range.length = podspecFile.length;
		[podspecFile replaceOccurrencesOfString:@"<Project Version>"
		                             withString:version
		                                options:NSLiteralSearch
		                                  range:range];
	}
    
	range.length = podspecFile.length;
	[podspecFile replaceOccurrencesOfString:@"'<"
	                             withString:@"'<#"
	                                options:NSLiteralSearch
	                                  range:range];
    
	range.length = podspecFile.length;
	[podspecFile replaceOccurrencesOfString:@">'"
	                             withString:@"#>'"
	                                options:NSLiteralSearch
	                                  range:range];
    
	// Reading dependencies
	NSString *podfileContent    = [NSString stringWithContentsOfFile:self.podfilePath encoding:NSUTF8StringEncoding error:nil];
	NSArray *fileLines          = [podfileContent componentsSeparatedByString:@"\n"];
    
	for (NSString *tmp in fileLines)
	{
		NSString *line = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
		if ([line rangeOfString:@"pod "].location == 0)
		{
			[podspecFile appendFormat:@"\n  s.dependencies =\t%@", line];
		}
	}
    
	[podspecFile appendString:@"\n\nend"];
    
	// Write Podspec File
	[[NSFileManager defaultManager] createFileAtPath:self.podspecPath contents:nil attributes:nil];
	[podspecFile writeToFile:self.podspecPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (BOOL)containsFileWithName:(NSString *)fileName
{
	NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
	return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

@end
