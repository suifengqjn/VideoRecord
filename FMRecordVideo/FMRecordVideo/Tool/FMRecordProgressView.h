//
//  FMRecordProgressView.h
//  fmvideo
//
//  Created by qianjn on 2016/12/30.
//  Copyright © 2016年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753
#import <UIKit/UIKit.h>

@interface FMRecordProgressView : UIView
- (instancetype)initWithFrame:(CGRect)frame;
-(void)updateProgressWithValue:(CGFloat)progress;
-(void)resetProgress;

@end
