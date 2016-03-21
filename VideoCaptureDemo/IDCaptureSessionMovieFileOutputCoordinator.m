//
//  IDCaptureSessionMovieFileOutputCoordinator.m
//  VideoCaptureDemo
//
//  Created by Adriaan Stellingwerff on 9/04/2015.
//  Copyright (c) 2015 Infoding. All rights reserved.
//

#import "IDCaptureSessionMovieFileOutputCoordinator.h"
#import "IDFileManager.h"

@interface IDCaptureSessionMovieFileOutputCoordinator () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

@end

@implementation IDCaptureSessionMovieFileOutputCoordinator

- (instancetype)init
{
    self = [super init];
    if(self){
        [self addMovieFileOutputToCaptureSession:self.captureSession];
    }
    return self;
}

#pragma mark - Private methods

- (BOOL)addMovieFileOutputToCaptureSession:(AVCaptureSession *)captureSession
{
    self.movieFileOutput = [AVCaptureMovieFileOutput new];
    return  [self addOutput:_movieFileOutput toCaptureSession:captureSession];
}

#pragma mark - Recording

- (void)startRecording
{
    IDFileManager *fm = [IDFileManager new];
    NSURL *tempURL = [fm tempFileURL];
    [_movieFileOutput startRecordingToOutputFileURL:tempURL recordingDelegate:self];
}

- (void)stopRecording
{
    [_movieFileOutput stopRecording];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate methods

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray *)connections
{
   //Recording started
    [self.delegate coordinatorDidBeginRecording:self];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
   //Recording finished - do something with the file at outputFileURL
    [self.delegate coordinator:self didFinishRecordingToOutputFileURL:outputFileURL error:error];

}


@end

