//
//  AVAssetWriteManager.h
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/15.
//  Copyright © 2017年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//录制状态，（这里把视频录制与写入合并成一个状态）
typedef NS_ENUM(NSInteger, FMRecordState) {
    FMRecordStateInit = 0,
    FMRecordStatePrepareRecording,
    FMRecordStateRecording,
    FMRecordStateFinish,
    FMRecordStateFail,
};

//录制视频的长宽比
typedef NS_ENUM(NSInteger, FMVideoViewType) {
    Type1X1 = 0,
    Type4X3,
    TypeFullScreen
};


@protocol AVAssetWriteManagerDelegate <NSObject>

- (void)finishWriting;
- (void)updateWritingProgress:(CGFloat)progress;

@end

@interface AVAssetWriteManager : NSObject

@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;

@property (nonatomic, assign) FMRecordState writeState;
@property (nonatomic, weak) id <AVAssetWriteManagerDelegate> delegate;
- (instancetype)initWithURL:(NSURL *)URL viewType:(FMVideoViewType )type;

- (void)startWrite;
- (void)stopWrite;
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType;
- (void)destroyWrite;
@end
