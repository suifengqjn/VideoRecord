//
//  IDCaptureSessionAssetWriterCoordinator.m
//  VideoCaptureDemo
//
//  Created by Adriaan Stellingwerff on 9/04/2015.
//  Copyright (c) 2015 Infoding. All rights reserved.
//

#import "IDCaptureSessionAssetWriterCoordinator.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import "IDAssetWriterCoordinator.h"
#import "IDFileManager.h"


typedef NS_ENUM( NSInteger, RecordingStatus )
{
    RecordingStatusIdle = 0,
    RecordingStatusStartingRecording,
    RecordingStatusRecording,
    RecordingStatusStoppingRecording,
}; // internal state machine


@interface IDCaptureSessionAssetWriterCoordinator () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, IDAssetWriterCoordinatorDelegate>

@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) dispatch_queue_t audioDataOutputQueue;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;

@property (nonatomic, strong) AVCaptureConnection *audioConnection;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;

@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;

@property (nonatomic, strong) AVAssetWriter *assetWriter;

@property (nonatomic, assign) RecordingStatus recordingStatus;
@property (nonatomic, strong) NSURL *recordingURL;

@property(nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property(nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;
@property(nonatomic, retain) IDAssetWriterCoordinator *assetWriterCoordinator;

@end

@implementation IDCaptureSessionAssetWriterCoordinator


- (instancetype)init
{
    self = [super init];
    if(self){
        self.videoDataOutputQueue = dispatch_queue_create( "com.example.capturesession.videodata", DISPATCH_QUEUE_SERIAL );
        dispatch_set_target_queue( _videoDataOutputQueue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 ) );
        self.audioDataOutputQueue = dispatch_queue_create( "com.example.capturesession.audiodata", DISPATCH_QUEUE_SERIAL );
        [self addDataOutputsToCaptureSession:self.captureSession];

    }
    return self;
}

#pragma mark - Recording

- (void)startRecording
{
    @synchronized(self)
    {
        if(_recordingStatus != RecordingStatusIdle) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Already recording" userInfo:nil];
            return;
        }
        [self transitionToRecordingStatus:RecordingStatusStartingRecording error:nil];
    }
    
    IDFileManager *fm = [IDFileManager new];
    _recordingURL = [fm tempFileURL];
    

    self.assetWriterCoordinator = [[IDAssetWriterCoordinator alloc] initWithURL:_recordingURL];
    if(_outputAudioFormatDescription != nil){
        [_assetWriterCoordinator addAudioTrackWithSourceFormatDescription:self.outputAudioFormatDescription settings:_audioCompressionSettings];
    }
    [_assetWriterCoordinator addVideoTrackWithSourceFormatDescription:self.outputVideoFormatDescription settings:_videoCompressionSettings];
    
    dispatch_queue_t callbackQueue = dispatch_queue_create( "com.example.capturesession.writercallback", DISPATCH_QUEUE_SERIAL ); // guarantee ordering of callbacks with a serial queue
    [_assetWriterCoordinator setDelegate:self callbackQueue:callbackQueue];
    [_assetWriterCoordinator prepareToRecord]; // asynchronous, will call us back with recorderDidFinishPreparing: or recorder:didFailWithError: when done
}

- (void)stopRecording
{
    @synchronized(self)
    {
        if (_recordingStatus != RecordingStatusRecording){
            return;
        }
        [self transitionToRecordingStatus:RecordingStatusStoppingRecording error:nil];
    }
    [self.assetWriterCoordinator finishRecording]; // asynchronous, will call us back with
}

#pragma mark - Private methods

- (void)addDataOutputsToCaptureSession:(AVCaptureSession *)captureSession
{
    self.videoDataOutput = [AVCaptureVideoDataOutput new];
    _videoDataOutput.videoSettings = nil;
    _videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    [_videoDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
    
    self.audioDataOutput = [AVCaptureAudioDataOutput new];
    [_audioDataOutput setSampleBufferDelegate:self queue:_audioDataOutputQueue];
   
    [self addOutput:_videoDataOutput toCaptureSession:self.captureSession];
    _videoConnection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [self addOutput:_audioDataOutput toCaptureSession:self.captureSession];
    _audioConnection = [_audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
    
    [self setCompressionSettings];
}

- (void)setupVideoPipelineWithInputFormatDescription:(CMFormatDescriptionRef)inputFormatDescription
{
    self.outputVideoFormatDescription = inputFormatDescription;
}

- (void)teardownVideoPipeline
{
    self.outputVideoFormatDescription = nil;
}

- (void)setCompressionSettings
{
    _videoCompressionSettings = [_videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie];
    _audioCompressionSettings = [_audioDataOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie];
}

#pragma mark - SampleBufferDelegate methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    if (connection == _videoConnection){
        if (self.outputVideoFormatDescription == nil) {
            // Don't render the first sample buffer.
            // This gives us one frame interval (33ms at 30fps) for setupVideoPipelineWithInputFormatDescription: to complete.
            // Ideally this would be done asynchronously to ensure frames don't back up on slower devices.
            
            //TODO: outputVideoFormatDescription should be updated whenever video configuration is changed (frame rate, etc.)
            //Currently we don't use the outputVideoFormatDescription in IDAssetWriterRecoredSession
            [self setupVideoPipelineWithInputFormatDescription:formatDescription];
        } else {
            self.outputVideoFormatDescription = formatDescription;
            @synchronized(self) {
                if(_recordingStatus == RecordingStatusRecording){
                    [_assetWriterCoordinator appendVideoSampleBuffer:sampleBuffer];
                }
            }
        }
    } else if ( connection == _audioConnection ){
        self.outputAudioFormatDescription = formatDescription;
        @synchronized( self ) {
            if(_recordingStatus == RecordingStatusRecording){
                [_assetWriterCoordinator appendAudioSampleBuffer:sampleBuffer];
            }
        }
    }
}

#pragma mark - IDAssetWriterCoordinatorDelegate methods

- (void)writerCoordinatorDidFinishPreparing:(IDAssetWriterCoordinator *)coordinator
{
    @synchronized(self)
    {
        if(_recordingStatus != RecordingStatusStartingRecording){
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Expected to be in StartingRecording state" userInfo:nil];
            return;
        }
        [self transitionToRecordingStatus:RecordingStatusRecording error:nil];
    }
}

- (void)writerCoordinator:(IDAssetWriterCoordinator *)recorder didFailWithError:(NSError *)error
{
    @synchronized( self ) {
        self.assetWriterCoordinator = nil;
        [self transitionToRecordingStatus:RecordingStatusIdle error:error];
    }
}

- (void)writerCoordinatorDidFinishRecording:(IDAssetWriterCoordinator *)coordinator
{
    @synchronized( self )
    {
        if ( _recordingStatus != RecordingStatusStoppingRecording ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Expected to be in StoppingRecording state" userInfo:nil];
            return;
        }
        // No state transition, we are still in the process of stopping.
        // We will be stopped once we save to the assets library.
    }
    
    self.assetWriterCoordinator = nil;
    
    @synchronized( self ) {
        [self transitionToRecordingStatus:RecordingStatusIdle error:nil];
    }
}


#pragma mark - Recording State Machine

// call under @synchonized( self )
- (void)transitionToRecordingStatus:(RecordingStatus)newStatus error:(NSError *)error
{
    RecordingStatus oldStatus = _recordingStatus;
    _recordingStatus = newStatus;
    
    if (newStatus != oldStatus){
        if (error && (newStatus == RecordingStatusIdle)){
            dispatch_async( self.delegateCallbackQueue, ^{
                @autoreleasepool
                {
                    [self.delegate coordinator:self didFinishRecordingToOutputFileURL:_recordingURL error:nil];
                }
            });
        } else {
            error = nil; // only the above delegate method takes an error
            if (oldStatus == RecordingStatusStartingRecording && newStatus == RecordingStatusRecording){
                dispatch_async( self.delegateCallbackQueue, ^{
                    @autoreleasepool
                    {
                        [self.delegate coordinatorDidBeginRecording:self];
                    }
                });
            } else if (oldStatus == RecordingStatusStoppingRecording && newStatus == RecordingStatusIdle) {
                dispatch_async( self.delegateCallbackQueue, ^{
                    @autoreleasepool
                    {
                        [self.delegate coordinator:self didFinishRecordingToOutputFileURL:_recordingURL error:nil];
                    }
                });
            }
        }
    }
}

@end