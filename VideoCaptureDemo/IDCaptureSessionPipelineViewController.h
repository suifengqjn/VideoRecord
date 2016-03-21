//
//  IDCaptureSessionPipelineViewController.h
//  VideoCaptureDemo
//
//  Created by Adriaan Stellingwerff on 9/04/2015.
//  Copyright (c) 2015 Infoding. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PipelineMode)
{
    PipelineModeMovieFileOutput = 0,
    PipelineModeAssetWriter,
}; // internal state machine

@interface IDCaptureSessionPipelineViewController : UIViewController

- (void)setupWithPipelineMode:(PipelineMode)mode;

@end
