//
//  FMWModel.h
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/15.
//  Copyright © 2017年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753

#import <Foundation/Foundation.h>
#import "AVAssetWriteManager.h"


//闪光灯状态
typedef NS_ENUM(NSInteger, FMFlashState) {
    FMFlashClose = 0,
    FMFlashOpen,
    FMFlashAuto,
};

@protocol FMWModelDelegate <NSObject>

- (void)updateFlashState:(FMFlashState)state;
- (void)updateRecordingProgress:(CGFloat)progress;
- (void)updateRecordState:(FMRecordState)recordState;

@end


@interface FMWModel : NSObject

@property (nonatomic, weak  ) id<FMWModelDelegate>delegate;
@property (nonatomic, assign) FMRecordState recordState;
@property (nonatomic, strong, readonly) NSURL *videoUrl;
- (instancetype)initWithFMVideoViewType:(FMVideoViewType )type superView:(UIView *)superView;

- (void)turnCameraAction;
- (void)switchflash;
- (void)startRecord;
- (void)stopRecord;
- (void)reset;


@end
