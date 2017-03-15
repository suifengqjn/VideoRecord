//
//  ViewController.m
//  FMRecordVideo
//
//  Created by qianjn on 2017/2/27.
//  Copyright © 2017年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753
#import "ViewController.h"
#import "FMImagePicker.h"
#import "FMFileVideoController.h"
#import "FMWriteVideoController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)UIImagePicker:(id)sender {
    
    FMImagePicker *picker = [[FMImagePicker alloc] init];
    [self presentViewController:picker animated:YES completion:nil];
    
}


- (IBAction)fileOut:(id)sender {
    
    FMFileVideoController *fileVC = [[FMFileVideoController alloc] init];
    UINavigationController *NAV = [[UINavigationController alloc] initWithRootViewController:fileVC];
    [self presentViewController:NAV animated:YES completion:nil];
    
    
}

- (IBAction)writer:(id)sender {
    
    FMWriteVideoController *writeVC = [[FMWriteVideoController alloc] init];
    UINavigationController *NAV = [[UINavigationController alloc] initWithRootViewController:writeVC];
    [self presentViewController:NAV animated:YES completion:nil];
    
}

@end
