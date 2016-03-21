//
//  IDCameraPermissionsManager.h
//  VideoCameraDemo
//
//  Created by Adriaan Stellingwerff on 10/03/2014.
//  Copyright (c) 2014 Infoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IDPermissionsManager : NSObject

- (void)checkMicrophonePermissionsWithBlock:(void(^)(BOOL granted))block;
- (void)checkCameraAuthorizationStatusWithBlock:(void(^)(BOOL granted))block;

@end