//
//  FMWriteVideoController.m
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/15.
//  Copyright © 2017年 SF. All rights reserved.
//

#import "FMWriteVideoController.h"
#import "FMWVideoView.h"
@interface FMWriteVideoController ()<FMWVideoViewDelegate>

@end

@implementation FMWriteVideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.hidden = YES;
    
    FMWVideoView *videoView  =[[FMWVideoView alloc] initWithFMVideoViewType:TypeFullScreen];
    videoView.delegate = self;
    [self.view addSubview:videoView];
    
    
    
}



@end
