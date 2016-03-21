//
//  IDCaptureSessionCoordinator.h
//  VideoCaptureDemo
//
//  Created by Adriaan Stellingwerff on 1/04/2015.
//  Copyright (c) 2015 Infoding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol IDCaptureSessionCoordinatorDelegate;

@interface IDCaptureSessionCoordinator : NSObject

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *cameraDevice;
@property (nonatomic, strong) dispatch_queue_t delegateCallbackQueue;
@property (nonatomic, weak) id<IDCaptureSessionCoordinatorDelegate> delegate;

- (void)setDelegate:(id<IDCaptureSessionCoordinatorDelegate>)delegate callbackQueue:(dispatch_queue_t)delegateCallbackQueue;

- (BOOL)addInput:(AVCaptureDeviceInput *)input toCaptureSession:(AVCaptureSession *)captureSession;
- (BOOL)addOutput:(AVCaptureOutput *)output toCaptureSession:(AVCaptureSession *)captureSession;

- (void)startRunning;
- (void)stopRunning;

- (void)startRecording;
- (void)stopRecording;

- (AVCaptureVideoPreviewLayer *)previewLayer;

@end

@protocol IDCaptureSessionCoordinatorDelegate <NSObject>

@required

- (void)coordinatorDidBeginRecording:(IDCaptureSessionCoordinator *)coordinator;
- (void)coordinator:(IDCaptureSessionCoordinator *)coordinator didFinishRecordingToOutputFileURL:(NSURL *)outputFileURL error:(NSError *)error;

@end
