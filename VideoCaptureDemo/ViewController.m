//
//  ViewController.m
//  VideoCaptureDemo
//
//  Created by Adriaan Stellingwerff on 31/03/2015.
//  Copyright (c) 2015 Infoding. All rights reserved.
//

#import "ViewController.h"
#import "IDImagePickerCoordinator.h"
#import "IDCaptureSessionPipelineViewController.h"

@interface ViewController () 

@property (nonatomic, strong) IDImagePickerCoordinator *imagePickerCoordinator;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            self.imagePickerCoordinator = [IDImagePickerCoordinator new];
            [self presentViewController:[_imagePickerCoordinator cameraVC] animated:YES completion:nil];
            break;
        case 1:
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            IDCaptureSessionPipelineViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"captureSessionVC"];
            [viewController setupWithPipelineMode:PipelineModeMovieFileOutput];
            [self presentViewController:viewController animated:YES completion:nil];
            break;
        }
        case 2:
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            IDCaptureSessionPipelineViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"captureSessionVC"];
            [viewController setupWithPipelineMode:PipelineModeAssetWriter];
            [self presentViewController:viewController animated:YES completion:nil];
            break;
        }
        default:
            break;
    }
}

@end
