//
//  FMFModel.h
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/12.
//  Copyright © 2017年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753
#import <Foundation/Foundation.h>



//录制视频的长宽比
typedef NS_ENUM(NSInteger, FMVideoViewType) {
    Type1X1 = 0,
    Type4X3,
    TypeFullScreen
};

//闪光灯状态
typedef NS_ENUM(NSInteger, FMFlashState) {
    FMFlashClose = 0,
    FMFlashOpen,
    FMFlashAuto,
};

//录制状态
typedef NS_ENUM(NSInteger, FMRecordState) {
    FMRecordStateInit = 0,
    FMRecordStateRecording,
    FMRecordStatePause,
    FMRecordStateFinish,
};

@protocol FMFModelDelegate <NSObject>

- (void)updateFlashState:(FMFlashState)state;
- (void)updateRecordingProgress:(CGFloat)progress;
- (void)updateRecordState:(FMRecordState)recordState;

@end

@interface FMFModel : NSObject

@property (nonatomic, weak  ) id<FMFModelDelegate>delegate;
@property (nonatomic, assign) FMRecordState recordState;
@property (nonatomic, strong, readonly) NSURL *videoUrl;
- (instancetype)initWithFMVideoViewType:(FMVideoViewType )type superView:(UIView *)superView;

- (void)turnCameraAction;
- (void)switchflash;
- (void)startRecord;
- (void)stopRecord;
- (void)reset;

@end
