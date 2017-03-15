//
//  FMWVideoView.h
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/15.
//  Copyright © 2017年 SF. All rights reserved.
//

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
