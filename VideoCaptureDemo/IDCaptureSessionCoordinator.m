//
//  IDCaptureSessionCoordinator.m
//  VideoCaptureDemo
//
//  Created by Adriaan Stellingwerff on 1/04/2015.
//  Copyright (c) 2015 Infoding. All rights reserved.
//

#import "IDCaptureSessionCoordinator.h"

@interface IDCaptureSessionCoordinator ()

@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation IDCaptureSessionCoordinator


- (instancetype)init
{
    self = [super init];
    if(self){
        _sessionQueue = dispatch_queue_create( "com.example.capturepipeline.session", DISPATCH_QUEUE_SERIAL );
        _captureSession = [self setupCaptureSession];
    }
    return self;
}

- (void)setDelegate:(id<IDCaptureSessionCoordinatorDelegate>)delegate callbackQueue:(dispatch_queue_t)delegateCallbackQueue
{
    if(delegate && ( delegateCallbackQueue == NULL)){
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Caller must provide a delegateCallbackQueue" userInfo:nil];
    }
    @synchronized(self)
    {
        _delegate = delegate;
        if (delegateCallbackQueue != _delegateCallbackQueue){
            _delegateCallbackQueue = delegateCallbackQueue;
        }
    }
}

- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if(!_previewLayer && _captureSession){
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    }
    return _previewLayer;
}

- (void)startRunning
{
    dispatch_sync( _sessionQueue, ^{
        [_captureSession startRunning];
    } );
}

- (void)stopRunning
{
    dispatch_sync( _sessionQueue, ^{
        // the captureSessionDidStopRunning method will stop recording if necessary as well, but we do it here so that the last video and audio samples are better aligned
        [self stopRecording]; // does nothing if we aren't currently recording
        [_captureSession stopRunning];
    } );
}


- (void)startRecording
{
    //overwritten by subclass
}

- (void)stopRecording
{
    //overwritten by subclass
}



#pragma mark - Capture Session Setup


- (AVCaptureSession *)setupCaptureSession
{
    AVCaptureSession *captureSession = [AVCaptureSession new];
    
    if(![self addDefaultCameraInputToCaptureSession:captureSession]){
        NSLog(@"failed to add camera input to capture session");
    }
    if(![self addDefaultMicInputToCaptureSession:captureSession]){
        NSLog(@"failed to add mic input to capture session");
    }
    
    return captureSession;
}

- (BOOL)addDefaultCameraInputToCaptureSession:(AVCaptureSession *)captureSession
{
    NSError *error;
    AVCaptureDeviceInput *cameraDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] error:&error];

    if(error){
        NSLog(@"error configuring camera input: %@", [error localizedDescription]);
        return NO;
    } else {
        BOOL success = [self addInput:cameraDeviceInput toCaptureSession:captureSession];
        _cameraDevice = cameraDeviceInput.device;
        return success;
    }
}

//Not used in this project, but illustration of how to select a specific camera
- (BOOL)addCameraAtPosition:(AVCaptureDevicePosition)position toCaptureSession:(AVCaptureSession *)captureSession
{
    NSError *error;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *cameraDeviceInput;
    for(AVCaptureDevice *device in devices){
        if(device.position == position){
            cameraDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
        }
    }
    if(!cameraDeviceInput){
        NSLog(@"No capture device found for requested position");
        return NO;
    }
    
    if(error){
        NSLog(@"error configuring camera input: %@", [error localizedDescription]);
        return NO;
    } else {
        BOOL success = [self addInput:cameraDeviceInput toCaptureSession:captureSession];
        _cameraDevice = cameraDeviceInput.device;
        return success;
    }
}

- (BOOL)addDefaultMicInputToCaptureSession:(AVCaptureSession *)captureSession
{
    NSError *error;
    AVCaptureDeviceInput *micDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error];
    if(error){
        NSLog(@"error configuring mic input: %@", [error localizedDescription]);
        return NO;
    } else {
        BOOL success = [self addInput:micDeviceInput toCaptureSession:captureSession];
        return success;
    }
}

- (BOOL)addInput:(AVCaptureDeviceInput *)input toCaptureSession:(AVCaptureSession *)captureSession
{
    if([captureSession canAddInput:input]){
        [captureSession addInput:input];
        return YES;
    } else {
        NSLog(@"can't add input: %@", [input description]);
    }
    return NO;
}


- (BOOL)addOutput:(AVCaptureOutput *)output toCaptureSession:(AVCaptureSession *)captureSession
{
    if([captureSession canAddOutput:output]){
        [captureSession addOutput:output];
        return YES;
    } else {
        NSLog(@"can't add output: %@", [output description]);
    }
    return NO;
}


#pragma mark - Methods discussed in the article but not used in this demo app

- (void)setFrameRateWithDuration:(CMTime)frameDuration OnCaptureDevice:(AVCaptureDevice *)device
{
    NSError *error;
    NSArray *supportedFrameRateRanges = [device.activeFormat videoSupportedFrameRateRanges];
    BOOL frameRateSupported = NO;
    for(AVFrameRateRange *range in supportedFrameRateRanges){
        if(CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) && CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)){
            frameRateSupported = YES;
        }
    }
    
    if(frameRateSupported && [device lockForConfiguration:&error]){
        [device setActiveVideoMaxFrameDuration:frameDuration];
        [device setActiveVideoMinFrameDuration:frameDuration];
        [device unlockForConfiguration];
    }
}


- (void)listCamerasAndMics
{
    NSLog(@"%@", [[AVCaptureDevice devices] description]);
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if(error){
        NSLog(@"%@", [error localizedDescription]);
    }
    [audioSession setActive:YES error:&error];
    
    NSArray *availableAudioInputs = [audioSession availableInputs];
    NSLog(@"audio inputs: %@", [availableAudioInputs description]);
    for(AVAudioSessionPortDescription *portDescription in availableAudioInputs){
        NSLog(@"data sources: %@", [[portDescription dataSources] description]);
    }
    if([availableAudioInputs count] > 0){
        AVAudioSessionPortDescription *portDescription = [availableAudioInputs firstObject];
        if([[portDescription dataSources] count] > 0){
            NSError *error;
            AVAudioSessionDataSourceDescription *dataSource = [[portDescription dataSources] lastObject];
            
            [portDescription setPreferredDataSource:dataSource error:&error];
            [self logError:error];
            
            [audioSession setPreferredInput:portDescription error:&error];
            [self logError:error];

            NSArray *availableAudioInputs = [audioSession availableInputs];
            NSLog(@"audio inputs: %@", [availableAudioInputs description]);
        
        }
    }
}

- (void)logError:(NSError *)error
{
    if(error){
        NSLog(@"%@", [error localizedDescription]);
    }
}

- (void)configureFrontMic
{
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if(error){
        NSLog(@"%@", [error localizedDescription]);
    }
    [audioSession setActive:YES error:&error];
    
    NSArray* inputs = [audioSession availableInputs];
    AVAudioSessionPortDescription *builtInMic = nil;
    for (AVAudioSessionPortDescription* port in inputs){
        if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic]){
            builtInMic = port;
            break;
        }
    }
    
    for (AVAudioSessionDataSourceDescription* source in builtInMic.dataSources){
        if ([source.orientation isEqual:AVAudioSessionOrientationFront]){
            [builtInMic setPreferredDataSource:source error:nil];
            [audioSession setPreferredInput:builtInMic error:&error];
            break;
        }
    }
}


@end