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
typedef NS_ENUM(NSInteger, FMFVideoViewType) {
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

@protocol FMFModelDelegate <NSObject>

- (void)updateFlashState:(FMFlashState)state;

@end

@interface FMFModel : NSObject

@property (nonatomic, weak  ) id<FMFModelDelegate>delegate;

- (instancetype)initWithFMFVideoViewType:(FMFVideoViewType )type superView:(UIView *)superView;

- (void)turnCameraAction;
- (void)switchflash;
- (void)startRecord;
- (void)stopRecord;
@end
