//
//  IDCameraPermissionsManager.m
//  VideoCameraDemo
//
//  Created by Adriaan Stellingwerff on 10/03/2014.
//  Copyright (c) 2014 Infoding. All rights reserved.
//

#import "IDPermissionsManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


@interface IDPermissionsManager () <UIAlertViewDelegate>


@end

@implementation IDPermissionsManager

- (void)checkMicrophonePermissionsWithBlock:(void(^)(BOOL granted))block
{
    NSString *mediaType = AVMediaTypeAudio;
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
    if(!granted){
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Microphone Disabled"
                                                   message:@"To enable sound recording with your video please go to the Settings app > Privacy > Microphone and enable access."
                                                  delegate:self
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:@"Settings", nil];
                alert.delegate = self;
                [alert show];
            });
        }
        if(block != nil)
            block(granted);
    }];
}


- (void)checkCameraAuthorizationStatusWithBlock:(void(^)(BOOL granted))block
{
	NSString *mediaType = AVMediaTypeVideo;
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (!granted){
            //Not granted access to mediaType
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera disabled"
                                                                message:@"This app doesn't have permission to use the camera, please go to the Settings app > Privacy > Camera and enable access."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:@"Settings", nil];
                alert.delegate = self;
                [alert show];
            });
        }
        if(block)
            block(granted);
    }];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}


@end
