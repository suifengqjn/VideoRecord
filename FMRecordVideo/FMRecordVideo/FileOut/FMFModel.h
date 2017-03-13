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

typedef NS_ENUM(NSInteger, FMFVideoViewType) {
    Type1X1 = 0,
    Type4X3,
    TypeFullScreen
};


@interface FMFModel : NSObject

- (instancetype)initWithFMFVideoViewType:(FMFVideoViewType )type superView:(UIView *)superView;

- (void)turnCameraAction;
- (void)flashAction;
- (void)startRecord;
- (void)stopRecord;
@end
