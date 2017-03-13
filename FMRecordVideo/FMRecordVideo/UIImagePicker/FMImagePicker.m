//
//  FMImagePicker.m
//  FMRecordVideo
//
//  Created by qianjn on 2017/2/27.
//  Copyright © 2017年 SF. All rights reserved.
//

#import "FMImagePicker.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface FMImagePicker ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

    
@end

@implementation FMImagePicker

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (![self isVideoRecordingAvailable]) {
        return;
    }
    self.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.mediaTypes = @[(NSString *)kUTTypeMovie];
    self.delegate = self;
    
    //    //隐藏系统自带UI
    //    self.showsCameraControls = YES;
    //    //设置摄像头
    //    [self switchCameraIsFront:NO];
    //    //设置视频画质类别
    //    self.videoQuality = UIImagePickerControllerQualityTypeMedium;
    //    //设置散光灯类型
    //    self.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
    //    //设置录制的最大时长
    //    self.videoMaximumDuration = 20;
}




#pragma mark 自定义方法

- (void)startRecorder
{
    [self startVideoCapture];
}


- (void)stopRecoder
{
    [self stopVideoCapture];
}

#pragma mark - Private methods
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

- (void)switchCameraIsFront:(BOOL)front
{
    if (front) {
        if([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]){
            [self setCameraDevice:UIImagePickerControllerCameraDeviceFront];
            
        }
    } else {
        if([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]){
            [self setCameraDevice:UIImagePickerControllerCameraDeviceRear];
            
        }
    }
}


//隐藏系统自带的UI，可以自定义UI
- (void)configureCustomUIOnImagePicker
{
    
    self.showsCameraControls = NO;
    
    UIView *cameraOverlay = [[UIView alloc] init];
    self.cameraOverlayView = cameraOverlay;
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //录制完的视频保存到相册
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
