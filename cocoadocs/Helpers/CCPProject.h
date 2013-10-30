//
//  CCPWorkspace.h
//  CocoaPods
//
//  Created by Flávio Caetano on 10/30/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface CCPProject : NSObject

@property (nonatomic, strong) NSString *directoryPath;

@property (nonatomic, strong) NSString *podspecPath;
@property (nonatomic, strong) NSString *podfilePath;

@property (nonatomic, strong) NSString *projectName;

@property (nonatomic, strong) NSDictionary *infoDictionary;

- (id)initWithSchemeName:(NSString *)name;

- (void)createPodspecFromTemplate:(NSString *)_template;

- (BOOL)hasPodfile;
- (BOOL)hasPodspecFile;

- (BOOL)containsFileWithName:(NSString *)fileName;



@end
