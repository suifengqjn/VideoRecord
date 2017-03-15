//
//  FMFVideoView.h
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/12.
//  Copyright © 2017年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753
#import <UIKit/UIKit.h>
#import "FMFModel.h"


@protocol FMFVideoViewDelegate <NSObject>

-(void)dismissVC;
-(void)recordFinishWithvideoUrl:(NSURL *)videoUrl;

@end


@interface FMFVideoView : UIView

@property (nonatomic, assign) FMVideoViewType viewType;
@property (nonatomic, strong, readonly) FMFModel *fmodel;
@property (nonatomic, weak) id <FMFVideoViewDelegate> delegate;

- (instancetype)initWithFMVideoViewType:(FMVideoViewType)type;
- (void)reset;

@end
