//
//  FMWVideoView.h
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/15.
//  Copyright © 2017年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753

#import <UIKit/UIKit.h>
#import "FMWModel.h"
@protocol FMWVideoViewDelegate <NSObject>

-(void)dismissVC;
-(void)recordFinishWithvideoUrl:(NSURL *)videoUrl;

@end


@interface FMWVideoView : UIView


@property (nonatomic, assign) FMVideoViewType viewType;
@property (nonatomic, strong, readonly) FMWModel *fmodel;
@property (nonatomic, weak) id <FMWVideoViewDelegate> delegate;

- (instancetype)initWithFMVideoViewType:(FMVideoViewType)type;
- (void)reset;

@end
