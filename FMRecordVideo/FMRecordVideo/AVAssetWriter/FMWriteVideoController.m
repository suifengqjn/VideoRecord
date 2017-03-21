//
//  FMWriteVideoController.m
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/15.
//  Copyright © 2017年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753

#import "FMWriteVideoController.h"
#import "FMWVideoView.h"
#import "FMVideoPlayController.h"
@interface FMWriteVideoController ()<FMWVideoViewDelegate>
@property (nonatomic, strong)FMWVideoView *videoView;
@end

@implementation FMWriteVideoController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.hidden = YES;
    
    _videoView  =[[FMWVideoView alloc] initWithFMVideoViewType:Type1X1];
    _videoView.delegate = self;
    [self.view addSubview:_videoView];
    self.view.backgroundColor = [UIColor blackColor];
    
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_videoView.fmodel.recordState == FMRecordStateFinish) {
        [_videoView.fmodel reset];
    }
}


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
