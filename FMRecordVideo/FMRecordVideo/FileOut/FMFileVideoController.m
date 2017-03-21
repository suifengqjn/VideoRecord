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
#import "FMVideoPlayController.h"
@interface FMFileVideoController ()<FMFVideoViewDelegate>
@property (nonatomic, strong) FMFVideoView *videoView;
@end

@implementation FMFileVideoController

- (BOOL)prefersStatusBarHidden{
    return YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = YES;
    self.view.backgroundColor = [UIColor blackColor];
    _videoView = [[FMFVideoView alloc] initWithFMVideoViewType:TypeFullScreen];
    _videoView.delegate = self;
    [self.view addSubview:_videoView];
    
    
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_videoView.fmodel.recordState == FMRecordStateFinish) {
        [_videoView reset];
    }
    
}
#pragma mark - FMFVideoViewDelegate
- (void)dismissVC
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)recordFinishWithvideoUrl:(NSURL *)videoUrl
{
    FMVideoPlayController *playVC = [[FMVideoPlayController alloc] init];
    playVC.videoUrl =  videoUrl;
    [self.navigationController pushViewController:playVC animated:YES];
}

@end
