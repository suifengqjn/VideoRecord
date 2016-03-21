//
//  IDAssetWriterCoordinator.m
//  VideoCaptureDemo
//
//  Created by Adriaan Stellingwerff on 9/04/2015.
//  Copyright (c) 2015 Infoding. All rights reserved.
//

#import "IDAssetWriterCoordinator.h"

typedef NS_ENUM(NSInteger, WriterStatus){
    WriterStatusIdle = 0,
    WriterStatusPreparingToRecord,
    WriterStatusRecording,
    WriterStatusFinishingRecordingPart1, // waiting for inflight buffers to be appended
    WriterStatusFinishingRecordingPart2, // calling finish writing on the asset writer
    WriterStatusFinished,	// terminal state
    WriterStatusFailed		// terminal state
}; // internal state machine

@interface IDAssetWriterCoordinator ()

@property (nonatomic, weak) id<IDAssetWriterCoordinatorDelegate> delegate;

@property (nonatomic, assign) WriterStatus status;

@property (nonatomic) dispatch_queue_t writingQueue;
@property (nonatomic) dispatch_queue_t delegateCallbackQueue;

@property (nonatomic) NSURL *URL;

@property (nonatomic) AVAssetWriter *assetWriter;
@property (nonatomic) BOOL haveStartedSession;

@property (nonatomic) CMFormatDescriptionRef audioTrackSourceFormatDescription;
@property (nonatomic) NSDictionary *audioTrackSettings;
@property (nonatomic) AVAssetWriterInput *audioInput;

@property (nonatomic) CMFormatDescriptionRef videoTrackSourceFormatDescription;
@property (nonatomic) CGAffineTransform videoTrackTransform;
@property (nonatomic) NSDictionary *videoTrackSettings;
@property (nonatomic) AVAssetWriterInput *videoInput;

@end

@implementation IDAssetWriterCoordinator


- (instancetype)initWithURL:(NSURL *)URL
{
    if (!URL) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _writingQueue = dispatch_queue_create( "com.example.assetwriter.writing", DISPATCH_QUEUE_SERIAL );
        _videoTrackTransform = CGAffineTransformMakeRotation(M_PI_2); //portrait orientation
        _URL = URL;
    }
    return self;
}

- (void)addVideoTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription settings:(NSDictionary *)videoSettings
{
    if ( formatDescription == NULL ){
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL format description" userInfo:nil];
        return;
    }
    @synchronized( self )
    {
        if (_status != WriterStatusIdle){
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add tracks while not idle" userInfo:nil];
            return;
        }
        
        if(_videoTrackSourceFormatDescription ){
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add more than one video track" userInfo:nil];
            return;
        }
        
        _videoTrackSourceFormatDescription = (CMFormatDescriptionRef)CFRetain( formatDescription );
        _videoTrackSettings = [videoSettings copy];
    }
}

- (void)addAudioTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription settings:(NSDictionary *)audioSettings
{
    if ( formatDescription == NULL ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL format description" userInfo:nil];
        return;
    }
    
    @synchronized( self )
    {
        if ( _status != WriterStatusIdle ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add tracks while not idle" userInfo:nil];
            return;
        }
        
        if ( _audioTrackSourceFormatDescription ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add more than one audio track" userInfo:nil];
            return;
        }
        
        _audioTrackSourceFormatDescription = (CMFormatDescriptionRef)CFRetain( formatDescription );
        _audioTrackSettings = [audioSettings copy];
    }
}


- (void)setDelegate:(id<IDAssetWriterCoordinatorDelegate>)delegate callbackQueue:(dispatch_queue_t)delegateCallbackQueue; // delegate is weak referenced
{
    if ( delegate && ( delegateCallbackQueue == NULL ) ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Caller must provide a delegateCallbackQueue" userInfo:nil];
    }
    
    @synchronized( self )
    {
        _delegate = delegate;
        if ( delegateCallbackQueue != _delegateCallbackQueue  ) {
            _delegateCallbackQueue = delegateCallbackQueue;
        }
    }
}

- (void)prepareToRecord
{
    @synchronized( self )
    {
        if (_status != WriterStatusIdle){
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Already prepared, cannot prepare again" userInfo:nil];
            return;
        }
        [self transitionToStatus:WriterStatusPreparingToRecord error:nil];
    }
    
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0 ), ^{
        @autoreleasepool
        {
            NSError *error = nil;
            // AVAssetWriter will not write over an existing file.
            [[NSFileManager defaultManager] removeItemAtURL:_URL error:NULL];
            _assetWriter = [[AVAssetWriter alloc] initWithURL:_URL fileType:AVFileTypeQuickTimeMovie error:&error];
            
            // Create and add inputs
            if (!error && _videoTrackSourceFormatDescription) {
                [self setupAssetWriterVideoInputWithSourceFormatDescription:_videoTrackSourceFormatDescription transform:_videoTrackTransform settings:_videoTrackSettings error:&error];
            }
            if(!error && _audioTrackSourceFormatDescription) {
                [self setupAssetWriterAudioInputWithSourceFormatDescription:_audioTrackSourceFormatDescription settings:_audioTrackSettings error:&error];
            }
            if(!error) {
                BOOL success = [_assetWriter startWriting];
                if (!success) {
                    error = _assetWriter.error;
                }
            }
            
            @synchronized(self)
            {
                if (error) {
                    [self transitionToStatus:WriterStatusFailed error:error];
                } else {
                    [self transitionToStatus:WriterStatusRecording error:nil];
                }
            }
        }
    } );
}

- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
}

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
}

- (void)finishRecording
{
    @synchronized(self)
    {
        BOOL shouldFinishRecording = NO;
        switch (_status)
        {
            case WriterStatusIdle:
            case WriterStatusPreparingToRecord:
            case WriterStatusFinishingRecordingPart1:
            case WriterStatusFinishingRecordingPart2:
            case WriterStatusFinished:
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not recording" userInfo:nil];
                break;
            case WriterStatusFailed:
                // From the client's perspective the movie recorder can asynchronously transition to an error state as the result of an append.
                // Because of this we are lenient when finishRecording is called and we are in an error state.
                NSLog( @"Recording has failed, nothing to do" );
                break;
            case WriterStatusRecording:
                shouldFinishRecording = YES;
                break;
        }
        
        if (shouldFinishRecording){
            [self transitionToStatus:WriterStatusFinishingRecordingPart1 error:nil];
        }
        else {
            return;
        }
    }
    
    dispatch_async( _writingQueue, ^{
        @autoreleasepool
        {
            @synchronized(self)
            {
                // We may have transitioned to an error state as we appended inflight buffers. In that case there is nothing to do now.
                if ( _status != WriterStatusFinishingRecordingPart1 ) {
                    return;
                }
                
                // It is not safe to call -[AVAssetWriter finishWriting*] concurrently with -[AVAssetWriterInput appendSampleBuffer:]
                // We transition to MovieRecorderStatusFinishingRecordingPart2 while on _writingQueue, which guarantees that no more buffers will be appended.
                [self transitionToStatus:WriterStatusFinishingRecordingPart2 error:nil];
            }
            [_assetWriter finishWritingWithCompletionHandler:^{
                @synchronized( self )
                {
                    NSError *error = _assetWriter.error;
                    if(error){
                        [self transitionToStatus:WriterStatusFailed error:error];
                    }
                    else {
                        [self transitionToStatus:WriterStatusFinished error:nil];
                    }
                }
            }];
        }
    } );
}


#pragma mark - Private methods

- (BOOL)setupAssetWriterAudioInputWithSourceFormatDescription:(CMFormatDescriptionRef)audioFormatDescription settings:(NSDictionary *)audioSettings error:(NSError **)errorOut
{
    if (!audioSettings) {
        audioSettings = @{ AVFormatIDKey : @(kAudioFormatMPEG4AAC) };
    }
    
    if ( [_assetWriter canApplyOutputSettings:audioSettings forMediaType:AVMediaTypeAudio] ){
        _audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioSettings sourceFormatHint:audioFormatDescription];
        _audioInput.expectsMediaDataInRealTime = YES;
        
        if ([_assetWriter canAddInput:_audioInput]){
            [_assetWriter addInput:_audioInput];
        } else {
            if (errorOut ) {
                *errorOut = [self cannotSetupInputError];
            }
            return NO;
        }
    }
    else
    {
        if (errorOut) {
            *errorOut = [self cannotSetupInputError];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)setupAssetWriterVideoInputWithSourceFormatDescription:(CMFormatDescriptionRef)videoFormatDescription transform:(CGAffineTransform)transform settings:(NSDictionary *)videoSettings error:(NSError **)errorOut
{
    if (!videoSettings){
        videoSettings = [self fallbackVideoSettingsForSourceFormatDescription:videoFormatDescription];
    }
    
    if ([_assetWriter canApplyOutputSettings:videoSettings forMediaType:AVMediaTypeVideo]){
        _videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings sourceFormatHint:videoFormatDescription];
        _videoInput.expectsMediaDataInRealTime = YES;
        _videoInput.transform = transform;
        
        if ([_assetWriter canAddInput:_videoInput]){
            [_assetWriter addInput:_videoInput];
        } else {
            if ( errorOut ) {
                *errorOut = [self cannotSetupInputError];
            }
            return NO;
        }
    } else {
        if ( errorOut ) {
            *errorOut = [self cannotSetupInputError];
        }
        return NO;
    }
    return YES;
}

- (NSDictionary *)fallbackVideoSettingsForSourceFormatDescription:(CMFormatDescriptionRef)videoFormatDescription
{
    float bitsPerPixel;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(videoFormatDescription);
    int numPixels = dimensions.width * dimensions.height;
    int bitsPerSecond;
    
    NSLog( @"No video settings provided, using default settings" );
    
    // Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
    if ( numPixels < ( 640 * 480 ) ) {
        bitsPerPixel = 4.05; // This bitrate approximately matches the quality produced by AVCaptureSessionPresetMedium or Low.
    }
    else {
        bitsPerPixel = 10.1; // This bitrate approximately matches the quality produced by AVCaptureSessionPresetHigh.
    }
    
    bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(30),
                                             AVVideoMaxKeyFrameIntervalKey : @(30) };
    
    return @{ AVVideoCodecKey : AVVideoCodecH264,
                       AVVideoWidthKey : @(dimensions.width),
                       AVVideoHeightKey : @(dimensions.height),
                       AVVideoCompressionPropertiesKey : compressionProperties };

}

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType
{
    if(sampleBuffer == NULL){
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL sample buffer" userInfo:nil];
        return;
    }
    
    @synchronized(self){
        if (_status < WriterStatusRecording){
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not ready to record yet" userInfo:nil];
            return;
        }
    }
    
    CFRetain(sampleBuffer);
    dispatch_async( _writingQueue, ^{
        @autoreleasepool
        {
            @synchronized(self)
            {
                // From the client's perspective the movie recorder can asynchronously transition to an error state as the result of an append.
                // Because of this we are lenient when samples are appended and we are no longer recording.
                // Instead of throwing an exception we just release the sample buffers and return.
                if (_status > WriterStatusFinishingRecordingPart1){
                    CFRelease(sampleBuffer);
                    return;
                }
            }
            
            if(!_haveStartedSession && mediaType == AVMediaTypeVideo) {
                [_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                _haveStartedSession = YES;
            }
            
            AVAssetWriterInput *input = ( mediaType == AVMediaTypeVideo ) ? _videoInput : _audioInput;
            
            if(input.readyForMoreMediaData){
                BOOL success = [input appendSampleBuffer:sampleBuffer];
                if (!success){
                    NSError *error = _assetWriter.error;
                    @synchronized(self){
                        [self transitionToStatus:WriterStatusFailed error:error];
                    }
                }
            } else {
                NSLog( @"%@ input not ready for more media data, dropping buffer", mediaType );
            }
            CFRelease(sampleBuffer);
        }
    } );
}

// call under @synchonized( self )
- (void)transitionToStatus:(WriterStatus)newStatus error:(NSError *)error
{
    BOOL shouldNotifyDelegate = NO;
    
    if (newStatus != _status){
        // terminal states
        if ((newStatus == WriterStatusFinished) || (newStatus == WriterStatusFailed)){
            shouldNotifyDelegate = YES;
            // make sure there are no more sample buffers in flight before we tear down the asset writer and inputs
            
            dispatch_async(_writingQueue, ^{
                _assetWriter = nil;
                _videoInput = nil;
                _audioInput = nil;
                if (newStatus == WriterStatusFailed) {
                    [[NSFileManager defaultManager] removeItemAtURL:_URL error:NULL];
                }
            } );
        } else if (newStatus == WriterStatusRecording){
            shouldNotifyDelegate = YES;
        }
        _status = newStatus;
    }
    
    if (shouldNotifyDelegate && self.delegate){
        dispatch_async( _delegateCallbackQueue, ^{
            
            @autoreleasepool
            {
                switch(newStatus){
                    case WriterStatusRecording:
                        [self.delegate writerCoordinatorDidFinishPreparing:self];
                        break;
                    case WriterStatusFinished:
                        [self.delegate writerCoordinatorDidFinishRecording:self];
                        break;
                    case WriterStatusFailed:
                        [self.delegate writerCoordinator:self didFailWithError:error];
                        break;
                    default:
                        break;
                }
            }
        });
    }
}

- (NSError *)cannotSetupInputError
{
    NSString *localizedDescription = NSLocalizedString( @"Recording cannot be started", nil );
    NSString *localizedFailureReason = NSLocalizedString( @"Cannot setup asset writer input.", nil );
    NSDictionary *errorDict = @{ NSLocalizedDescriptionKey : localizedDescription,
                                 NSLocalizedFailureReasonErrorKey : localizedFailureReason };
    return [NSError errorWithDomain:@"com.example" code:0 userInfo:errorDict];
}

@end
