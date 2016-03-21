//
//  IDImagePickerCoordinator.m
//  VideoCaptureDemo
//
//  Created by Adriaan Stellingwerff on 1/04/2015.
//  Copyright (c) 2015 Infoding. All rights reserved.
//

#import "IDImagePickerCoordinator.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface IDImagePickerCoordinator () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *camera;

@end

@implementation IDImagePickerCoordinator


- (instancetype)init
{
    self = [super init];
    if(self){
        _camera = [self setupImagePicker];
    }
    return self;
}

- (UIImagePickerController *)cameraVC
{
    return _camera;
}

#pragma mark - Private methods

- (UIImagePickerController *)setupImagePicker
{
    UIImagePickerController *camera;
    if([self isVideoRecordingAvailable]){
        camera = [UIImagePickerController new];
        camera.sourceType = UIImagePickerControllerSourceTypeCamera;
        camera.mediaTypes = @[(NSString *)kUTTypeMovie];
        camera.delegate = self;
    }
    return camera;
}


- (BOOL)isVideoRecordingAvailable
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if([availableMediaTypes containsObject:(NSString *)kUTTypeMovie]){
            return YES;
        }
    }
    return NO;
}

- (BOOL)setFrontFacingCameraOnImagePicker:(UIImagePickerController *)picker
{
    if([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]){
        [picker setCameraDevice:UIImagePickerControllerCameraDeviceFront];
        return YES;
    }
    return NO;
}

- (void)configureCustomUIOnImagePicker:(UIImagePickerController *)picker
{
    UIView *cameraOverlay = [[UIView alloc] init];
    picker.showsCameraControls = NO;
    picker.cameraOverlayView = cameraOverlay;
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    NSURL *recordedVideoURL= [info objectForKey:UIImagePickerControllerMediaURL];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:recordedVideoURL]) {
        [library writeVideoAtPathToSavedPhotosAlbum:recordedVideoURL
                                    completionBlock:^(NSURL *assetURL, NSError *error){}
         ];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


@end
