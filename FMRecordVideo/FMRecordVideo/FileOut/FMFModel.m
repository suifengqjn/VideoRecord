//
//  FMFModel.m
//  FMRecordVideo
//
//  Created by qianjn on 2017/3/12.
//  Copyright © 2017年 SF. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753
#import "FMFModel.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "XCFileManager.h"


#define IS_IPHONE_4 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)480) < DBL_EPSILON)

@interface FMFModel ()<AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, weak) UIView *superView;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewlayer;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *FileOutput;

@property (strong,nonatomic)  UIImageView *focusCursor; //聚焦光标

@property (nonatomic, strong, readwrite) NSURL *videoUrl;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat recordTime;


@property (nonatomic, assign) FMFlashState flashState;

@end

@implementation FMFModel


- (instancetype)initWithFMVideoViewType:(FMVideoViewType)type superView:(UIView *)superView
{
    self = [super init];
    if (self) {
        _superView = superView;
        [self setUpWithType:type];
    }
    return self;
}

#pragma mark - lazy load
- (AVCaptureSession *)session
{
    // 录制5秒钟视频 高画质10M,压缩成中画质 0.5M
    // 录制5秒钟视频 中画质0.5M,压缩成中画质 0.5M
    // 录制5秒钟视频 低画质0.1M,压缩成中画质 0.1M
    // 只有高分辨率的视频才是全屏的，如果想要自定义长宽比，就需要先录制高分辨率，再剪裁，如果录制低分辨率，剪裁的区域不好控制
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {//设置分辨率
            _session.sessionPreset=AVCaptureSessionPresetHigh;
        }
    }
    return _session;
}

- (AVCaptureVideoPreviewLayer *)previewlayer
{
    if (!_previewlayer) {
        _previewlayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewlayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewlayer;
}

- (void)setRecordState:(FMRecordState)recordState
{
    if (_recordState != recordState) {
        _recordState = recordState;
        if (self.delegate && [self.delegate respondsToSelector:@selector(updateRecordState:)]) {
            [self.delegate updateRecordState:_recordState];
        }
    }
}

- (UIImageView *)focusCursor
{
    if (!_focusCursor) {
        _focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 50, 50)];
        _focusCursor.image = [UIImage imageNamed:@"focusImg"];
        _focusCursor.alpha = 0;
    }
    return _focusCursor;
}

#pragma mark - setup
- (void)setUpWithType:(FMVideoViewType )type
{
    ///0. 初始化捕捉会话，数据的采集都在会话中处理
    [self setUpInit];
    
    ///1. 设置视频的输入
    [self setUpVideo];
    
    ///2. 设置音频的输入
    [self setUpAudio];
    
    ///3.添加写入文件的fileoutput
    [self setUpFileOut];
    
    ///4. 视频的预览层
    [self setUpPreviewLayerWithType:type];
    
    ///5. 开始采集画面
    [self.session startRunning];
    
    /// 6. 将采集的数据写入文件（用户点击按钮即可将采集到的数据写入文件）
    
    /// 7. 增加聚焦功能（可有可无）
    [self addFocus];
    
}

- (void)setUpVideo
{
    // 1.1 获取视频输入设备(摄像头)
    AVCaptureDevice *videoCaptureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
    
    // 视频 HDR (高动态范围图像)
    // videoCaptureDevice.videoHDREnabled = YES;
    // 设置最大，最小帧速率
    //videoCaptureDevice.activeVideoMinFrameDuration = CMTimeMake(1, 60);
    // 1.2 创建视频输入源
    NSError *error=nil;
    self.videoInput= [[AVCaptureDeviceInput alloc] initWithDevice:videoCaptureDevice error:&error];
    // 1.3 将视频输入源添加到会话
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
        
    }
}
- (void)setUpAudio
{
    // 2.1 获取音频输入设备
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    NSError *error=nil;
    // 2.2 创建音频输入源
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    // 2.3 将音频输入源添加到会话
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
}

- (void)setUpFileOut
{
    // 3.1初始化设备输出对象，用于获得输出数据
    self.FileOutput=[[AVCaptureMovieFileOutput alloc]init];
    
    // 3.2设置输出对象的一些属性
    AVCaptureConnection *captureConnection=[self.FileOutput connectionWithMediaType:AVMediaTypeVideo];
    //设置防抖
    //视频防抖 是在 iOS 6 和 iPhone 4S 发布时引入的功能。到了 iPhone 6，增加了更强劲和流畅的防抖模式，被称为影院级的视频防抖动。相关的 API 也有所改动 (目前为止并没有在文档中反映出来，不过可以查看头文件）。防抖并不是在捕获设备上配置的，而是在 AVCaptureConnection 上设置。由于不是所有的设备格式都支持全部的防抖模式，所以在实际应用中应事先确认具体的防抖模式是否支持：
    if ([captureConnection isVideoStabilizationSupported ]) {
        captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
    }
    //预览图层和视频方向保持一致
    captureConnection.videoOrientation = [self.previewlayer connection].videoOrientation;
    
    // 3.3将设备输出添加到会话中
    if ([_session canAddOutput:_FileOutput]) {
        [_session addOutput:_FileOutput];
    }
}

- (void)setUpPreviewLayerWithType:(FMVideoViewType )type
{
    CGRect rect = CGRectZero;
    switch (type) {
        case Type1X1:
            rect = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
            break;
        case Type4X3:
            rect = CGRectMake(0, 0, kScreenWidth, kScreenWidth*4/3);
            break;
        case TypeFullScreen:
            rect = [UIScreen mainScreen].bounds;
            break;
        default:
            rect = [UIScreen mainScreen].bounds;
            break;
    }
    
    self.previewlayer.frame = rect;
    [_superView.layer insertSublayer:self.previewlayer atIndex:0];
}

- (void)writeDataTofile
{
    NSString *videoPath = [self createVideoFilePath];
    self.videoUrl = [NSURL fileURLWithPath:videoPath];
    [self.FileOutput startRecordingToOutputFileURL:self.videoUrl recordingDelegate:self];
    
}

//添加视频聚焦
- (void)addFocus
{
    [self.superView addSubview:self.focusCursor];
    UITapGestureRecognizer *tapGesture= [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.superView addGestureRecognizer:tapGesture];
}

-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    CGPoint point= [tapGesture locationInView:self.superView];
    //将UI坐标转化为摄像头坐标
    CGPoint cameraPoint= [self.previewlayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}


-(void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusCursor.center=point;
    self.focusCursor.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursor.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha=0;
        
    }];
}
//设置聚焦点
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

-(void)changeDeviceProperty:(void(^)(AVCaptureDevice *captureDevice))propertyChange{
    AVCaptureDevice *captureDevice= [self.videoInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}
#pragma mark - public method
//切换摄像头
- (void)turnCameraAction
{
    [self.session stopRunning];
    // 1. 获取当前摄像头
    AVCaptureDevicePosition position = self.videoInput.device.position;
    
    //2. 获取当前需要展示的摄像头
    if (position == AVCaptureDevicePositionBack) {
        position = AVCaptureDevicePositionFront;
    } else {
        position = AVCaptureDevicePositionBack;
    }
    
    // 3. 根据当前摄像头创建新的device
    AVCaptureDevice *device = [self getCameraDeviceWithPosition:position];
    
    // 4. 根据新的device创建input
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    //5. 在session中切换input
    [self.session beginConfiguration];
    [self.session removeInput:self.videoInput];
    [self.session addInput:newInput];
    [self.session commitConfiguration];
    self.videoInput = newInput;
    
    [self.session startRunning];
    
}


- (void)switchflash
{
    if(_flashState == FMFlashClose){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeOn];
            [self.videoInput.device unlockForConfiguration];
            _flashState = FMFlashOpen;
        }
    }else if(_flashState == FMFlashOpen){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeAuto];
            [self.videoInput.device unlockForConfiguration];
            _flashState = FMFlashAuto;
        }
    }else if(_flashState == FMFlashAuto){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeOff];
            [self.videoInput.device unlockForConfiguration];
            _flashState = FMFlashClose;
        }
    };
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateFlashState:)]) {
        [self.delegate updateFlashState:_flashState];
    }

}


- (void)startRecord
{
    [self writeDataTofile];
}

- (void)stopRecord
{
    [self.FileOutput stopRecording];
    [self.session stopRunning];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)reset
{
    self.recordState = FMRecordStateInit;
    _recordTime = 0;
    [self.session startRunning];
}
#pragma mark - private method
//初始化设置
- (void)setUpInit
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBack) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self clearFile];
    _recordTime = 0;
    _recordState = FMRecordStateInit;
    
}
//存放视频的文件夹
- (NSString *)videoFolder
{
    NSString *cacheDir = [XCFileManager cachesDir];
    NSString *direc = [cacheDir stringByAppendingPathComponent:VIDEO_FOLDER];
    if (![XCFileManager isExistsAtPath:direc]) {
        [XCFileManager createDirectoryAtPath:direc];
    }
    return direc;
}
//清空文件夹
- (void)clearFile
{
    [XCFileManager removeItemAtPath:[self videoFolder]];
    
}
//写入的视频路径
- (NSString *)createVideoFilePath
{
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString];
    NSString *path = [[self videoFolder] stringByAppendingPathComponent:videoName];
    return path;
    
}

- (void)refreshTimeLabel
{
    _recordTime += TIMER_INTERVAL;
    if(self.delegate && [self.delegate respondsToSelector:@selector(updateRecordingProgress:)]) {
        [self.delegate updateRecordingProgress:_recordTime/RECORD_MAX_TIME];
    }
    if (_recordTime >= RECORD_MAX_TIME) {
        [self stopRecord];
    }
}

#pragma mark - 获取摄像头
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}


#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray *)connections
{
    self.recordState = FMRecordStateRecording;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(refreshTimeLabel) userInfo:nil repeats:YES];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    
    if ([XCFileManager isExistsAtPath:[self.videoUrl path]]) {
        
        self.recordState = FMRecordStateFinish;
        //剪裁成正方形
        //[self cutVideoWithFinished:nil];
        
    }
    
}

#pragma mark - notification
- (void)enterBack
{
    self.videoUrl = nil;
    [self stopRecord];
}

- (void)becomeActive
{
    [self reset];
}

- (void)dealloc
{
    [self.timer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//#pragma mark - 导出视频
//- (void)convertVideoWithURL:(NSURL *)fileUrl{
//    
//    __block NSURL *outputFileURL = fileUrl;
//    NSString *path = [self createVideoFilePath];
//    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:outputFileURL options:nil];
//    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
//    __weak __typeof(self)weakSelf = self;
//    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality])
//    {
//        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
//        exportSession.outputURL = [[NSURL alloc] initFileURLWithPath:path];
//        exportSession.outputFileType = AVFileTypeMPEG4;
//        [exportSession exportAsynchronouslyWithCompletionHandler:^{
//            
//            switch ([exportSession status]) {
//                case AVAssetExportSessionStatusFailed:
//                    break;
//                case AVAssetExportSessionStatusCancelled:
//                    break;
//                case AVAssetExportSessionStatusCompleted:
//                    
//                    [weakSelf completeWithUrl:exportSession.outputURL];
//                    break;
//                default:
//                    break;
//            }
//        }];
//    }
//}
// 写入相册
//- (void)completeWithUrl:(NSURL *)url{
//    ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
//    [lib writeVideoAtPathToSavedPhotosAlbum:url completionBlock:nil];
//}


///完成剪裁
//test
- (void)cutVideoWithFinished:(void (^)(void))finished
{
    
    //1 — 采集
    AVAsset *asset = [AVAsset assetWithURL:self.videoUrl];
    // 2 创建AVMutableComposition实例. apple developer 里边的解释 【AVMutableComposition is a mutable subclass of AVComposition you use when you want to
    // create a new composition from existing assets. You can add and remove tracks, and you can add, remove, and scale time ranges.】
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    
    // 3 视频通道  工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    //获取duration的时候，不要用asset.duration，应该用track.timeRange.duration，用前者的时间不准确，会导致黑帧
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    
    // 4. 音频通道
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *audioAssetTrack =[[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    //5 创建视频组合图层指令AVMutableVideoCompositionLayerInstruction，并设置图层指令在视频的作用时间范围和旋转矩阵变换
    CMTime totalDuration = kCMTimeZero;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    totalDuration = CMTimeAdd(totalDuration, videoAssetTrack.timeRange.duration);
    CGAffineTransform t1;
    t1 = CGAffineTransformMakeTranslation(-1*videoAssetTrack.naturalSize.width/2, -1*videoAssetTrack.naturalSize.height/2);
    [layerInstruction setTransform:t1 atTime:kCMTimeZero];
    // 6.videoAssetTrack.naturalSize 就是录制的视频的实际宽高
    CGSize renderSize = CGSizeMake(0, 0);
    renderSize.width = MAX(renderSize.width, videoAssetTrack.naturalSize.height);
    renderSize.height = MAX(renderSize.height, videoAssetTrack.naturalSize.width);
    CGFloat renderW = MIN(renderSize.width, renderSize.height);
    CGFloat rate;
    rate = renderW / MIN(videoAssetTrack.naturalSize.width, videoAssetTrack.naturalSize.height);

    
    // 7. 根据录制视频时的方向旋转视频
    CGAffineTransform layerTransform = CGAffineTransformMake(videoAssetTrack.preferredTransform.a, videoAssetTrack.preferredTransform.b, videoAssetTrack.preferredTransform.c, videoAssetTrack.preferredTransform.d, videoAssetTrack.preferredTransform.tx * rate, videoAssetTrack.preferredTransform.ty * rate);
    layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(videoAssetTrack.naturalSize.width - videoAssetTrack.naturalSize.height) / 2.0));
    layerTransform = CGAffineTransformScale(layerTransform, rate, rate);
    [layerInstruction setTransform:layerTransform atTime:kCMTimeZero];
    [layerInstruction setOpacity:0.0 atTime:totalDuration];
    
    //8. 创建视频组合指令AVMutableVideoCompositionInstruction，并设置指令在视频的作用时间范围和旋转矩阵变换
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    instruction.layerInstructions = @[layerInstruction];
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.instructions = @[instruction];
    mainComposition.frameDuration = CMTimeMake(1, 30);
    
    mainComposition.renderSize = CGSizeMake(renderW,renderW);
    
    NSString* outputPath = [self createVideoFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]){
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    }
    
    NSURL *outurl = [[NSURL alloc] initFileURLWithPath:outputPath];
    // 9.导出视频
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    exporter.videoComposition = mainComposition;
    exporter.outputURL = outurl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
            [lib writeVideoAtPathToSavedPhotosAlbum:outurl completionBlock:nil];
        });
        
    }];
    
    

    
}

//- (void)cropPureVideoWithURL:(NSURL *)url scaleType:(NSInteger)scaleType finish:(void (^)(void))block {
//    
//    AVAsset *asset = [AVAsset assetWithURL:url];
//    
//    NSString* docFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//    NSString* outputPath = [docFolder stringByAppendingPathComponent:@"pureVideo.mp4"];
//    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
//        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
//    
//    UIImageOrientation videoOrientation = UIImageOrientationDown;//[self getVideoOrientationFromAsset:asset];
//    // input clip
//    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
//    
//    
//    // make it square
//    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
//    //    videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height);
//    videoComposition.frameDuration = CMTimeMake(1, 30);
//    
//    AVMutableVideoCompositionInstruction *instruction =[AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30) );
//    
//    // rotate to portrait
//    AVMutableVideoCompositionLayerInstruction* transformer =[AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
//    //    CGAffineTransform t1 = CGAffineTransformMakeTranslation(0,-80);
//    //    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
//    
//    CGRect cropRect = CGRectZero;
//    CGSize naturalSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.width);
//    
//    if (scaleType == 1) {
//        cropRect = CGRectMake(0, 0, naturalSize.width, naturalSize.width);
//    } else if (scaleType == 2) {
//        cropRect = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
//    } else if (scaleType == 0) {
//        CGFloat height = 0;
//        
//        height = naturalSize.height * (3.0 / 4.0);
//        
//        
//        cropRect = CGRectMake(0, 0, naturalSize.width, height);
//    };
//    
//    CGFloat cropOffX = cropRect.origin.x;
//    CGFloat cropOffY = cropRect.origin.y;
//    CGFloat cropWidth = cropRect.size.width;
//    CGFloat cropHeight = cropRect.size.height;
//    videoComposition.renderSize = CGSizeMake(cropWidth, cropHeight);
//    
//    CGAffineTransform t1 = CGAffineTransformIdentity;
//    CGAffineTransform t2 = CGAffineTransformIdentity;
//    
//    switch (videoOrientation) {
//        case UIImageOrientationUp:
//            t1 = CGAffineTransformMakeTranslation(naturalSize.height - cropOffX, 0 - cropOffY );
//            t2 = CGAffineTransformRotate(t1, M_PI_2 );
//            break;
//        case UIImageOrientationDown:
//            t1 = CGAffineTransformMakeTranslation(0 - cropOffX, naturalSize.height - cropOffY ); // not fixed width is the real height in upside down
//            t2 = CGAffineTransformRotate(t1, - M_PI_2 );
//            break;
//        case UIImageOrientationRight:
//            t1 = CGAffineTransformMakeTranslation(0 - cropOffY, 0 - cropOffX );
//            t2 = CGAffineTransformRotate(t1, 0 );
//            break;
//        case UIImageOrientationLeft:
//            t1 = CGAffineTransformMakeTranslation(naturalSize.width - cropOffX, naturalSize.height - cropOffY );
//            t2 = CGAffineTransformRotate(t1, M_PI );
//            break;
//        default:
//            NSLog(@"no supported orientation has been found in this video");
//            break;
//    }
//    
//    CGAffineTransform finalTransform = t2;
//    [transformer setTransform:finalTransform atTime:kCMTimeZero];
//    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
//    videoComposition.instructions = [NSArray arrayWithObject: instruction];
//    
//    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
//    
//    // export
//    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:videoComposition presetName:AVAssetExportPresetMediumQuality];
//    exporter.videoComposition = videoComposition;
//    exporter.outputURL=outputURL;
//    exporter.outputFileType=AVFileTypeQuickTimeMovie;
//    
//    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
//        if (exporter.status == AVAssetExportSessionStatusCompleted) {
//           
//        } else {
//           
//        }
//    }];
//}






@end
