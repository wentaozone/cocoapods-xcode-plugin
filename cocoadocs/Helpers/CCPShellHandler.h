//
//  CCPShellHandler.h
//  CocoaPods
//
//  Created by Delisa Mason on 7/11/13.
//  Copyright (c) 2013 Delisa Mason. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCPShellHandler : NSObject

+ (void)runShellCommand:(NSString *)command withArgs:(NSArray *)args directory:(NSString *)directory completion:(void(^)(NSTask *t))completion;

@end
