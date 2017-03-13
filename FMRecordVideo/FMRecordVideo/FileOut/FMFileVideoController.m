//
//  FMFileVideoController.m
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/12.
//  Copyright © 2017年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753
#import "FMFileVideoController.h"
#import "FMFVideoView.h"
@interface FMFileVideoController ()

@end

@implementation FMFileVideoController

- (BOOL)prefersStatusBarHidden{
    return YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor grayColor];
    FMFVideoView *videoView = [[FMFVideoView alloc] initWithFMFVideoViewType:TypeFullScreen];
    __weak __typeof(self)weakSelf = self;
    [self.view addSubview:videoView];
    videoView.dismissblock = ^(){
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
    
}



@end
