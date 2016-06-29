//
//  QETakeMovieViewController.m
//  QETakeMovie
//
//  Created by user on 16/6/24.
//  Copyright © 2016年 mobin. All rights reserved.
//

#import "QETakeMovieViewController.h"
#import "QECameraView.h"
#import "Masonry.h"
#import "MBCamera.h"
#import "PlayVideoViewController.h"

#define TIMER_INTERVAL 0.05
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface QETakeMovieViewController ()<QECameraViewDelegate,AVCaptureFileOutputRecordingDelegate>
{

    MBCamera *_camera;
    UIImageView *_preView;
    CALayer *_progressLayer;
    NSTimer *_timer;
    CGFloat _currentTime;
    BOOL isStart;
    BOOL isCancel;
    NSMutableArray* urlArray;//保存视频片段的数组
    float preLayerWidth;//镜头宽
    float preLayerHeight;//镜头高
    float preLayerHWRate; //高，宽比
    float progressStep; //进度条每次变长的最小单位
    NSURL *_mergeFileURL;







    

}

@property (nonatomic,weak) QECameraView *cameraView;
@property (nonatomic,assign) CGFloat cameraTime; //拍摄时间
@property (nonatomic,assign) NSInteger frameNum; //帧数


@end

static NSString *const VIDEO_FOLDER = @"videoFolder";
@implementation QETakeMovieViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    urlArray = [[NSMutableArray alloc]init];
    self.cameraTime = 20;
    progressStep = SCREEN_WIDTH*TIMER_INTERVAL/self.cameraTime;

    
    /****** view *****/
    QECameraView *camera = ({
        QECameraView *view = [[QECameraView alloc]init];
        view.delegate = self;
        view;
    });
    self.cameraView = camera;
    [self.view addSubview:camera];
    [camera mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left);
        make.right.mas_equalTo(self.view.mas_right);
        make.top.mas_equalTo(self.view.mas_top).offset(64.0);
        make.bottom.mas_equalTo(self.view.mas_bottom);
    }];
       //相机权限受限提示
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied ||authStatus == AVAuthorizationStatusRestricted) {
        NSLog(@"相机权限受限");
    }
    
    [self createVideoFolderIfNotExist];
    
    UIBarButtonItem *finishButton = [[UIBarButtonItem alloc]initWithTitle:@"下一步" style:UIBarButtonItemStylePlain target:self action:@selector(nextStep:)];
    finishButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = finishButton;
    

}

#pragma mark --下一步
- (void)nextStep:(UIBarButtonItem *)sender
{
    if (urlArray.count != 0) {
        PlayVideoViewController* view = [[PlayVideoViewController alloc]init];
        view.videoURL = _mergeFileURL;
        [self.navigationController pushViewController:view animated:YES];

    }
    

}

#pragma mark --文件相关
//创建视频路径
- (void)createVideoFolderIfNotExist
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    NSString *folderPath = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建保存视频文件夹失败");
        }
    }
}

//录制保存的时候要保存为 mov
- (NSString *)getVideoSaveFilePathString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mov"];
    
    NSLog(@"----flieName--%@---path--%@",fileName,path);
    
    return fileName;
}


#pragma mark -- init
- (void)initCamera
{
    _camera = [[MBCamera alloc]init];
    [_camera embedLayerWithView:self.cameraView.preView];
    //_camera.frameNum = _frameNum;
    [_camera startCamera];
}

- (void)viewDidLayoutSubviews
{

    [super viewDidLayoutSubviews];
    
    [self initCamera];
    preLayerWidth = _camera.preView.frame.size.width;
    preLayerHeight = _camera.preView.frame.size.height;
    preLayerHWRate = preLayerHeight/preLayerWidth;
}

-(void)progressAddAnimation{
    
    float progressWidth = self.cameraView.progressView.frame.size.width+progressStep;
    [self.cameraView.progressView setFrame:CGRectMake(0, 0, progressWidth, 8)];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self resetVideoData];

}
- (void)resetVideoData
{
    //还原数据-----------
    [self deleteAllVideos];
    _currentTime = 0;
    self.cameraView.progressView.frame = CGRectMake(0,0,0,8);
    self.navigationItem.rightBarButtonItem.enabled = NO;
}
- (void)deleteAllVideos
{
    for (NSURL *videoFileURL in urlArray) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *filePath = [[videoFileURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:filePath]) {
                NSError *error = nil;
                [fileManager removeItemAtPath:filePath error:&error];
                
                if (error) {
                    NSLog(@"delete All Video 删除视频文件出错:%@", error);
                }
            }
        });
    }
    [urlArray removeAllObjects];
}


#pragma mark --QECameraViewDelegate
/****** 交换摄像头 *****/
- (void)cameraViewDidChangeCarame:(UIButton *)cameraButton
{

    NSLog(@"交换摄像头");
    
    AVCaptureDevice *currentDevice=[_camera.videoCaptureDeviceInput device];
    AVCaptureDevicePosition currentPosition=[currentDevice position];
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition=AVCaptureDevicePositionFront;
    if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront) {
        toChangePosition=AVCaptureDevicePositionBack;
        _cameraView.flashButton.hidden = NO;
    }else{
        _cameraView.flashButton.hidden = YES;
    }
    toChangeDevice=[self getCameraDeviceWithPosition:toChangePosition];
    //获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [_camera.session  beginConfiguration];
    //移除原有输入对象
    [_camera.session removeInput:_camera.videoCaptureDeviceInput];
    //添加新的输入对象
    if ([_camera.session canAddInput:toChangeDeviceInput]) {
        [_camera.session addInput:toChangeDeviceInput];
        _camera.videoCaptureDeviceInput = toChangeDeviceInput;
    }
    //提交会话配置
    [_camera.session commitConfiguration];
    
    //关闭闪光灯
    _cameraView.flashButton.selected = NO;
    [_cameraView.flashButton setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
    [self setTorchMode:AVCaptureTorchModeOff];
    

}
/****** 打开闪光灯 *****/
- (void)cameraViewDidOpenFlash:(UIButton *)falshButton
{

    NSLog(@"打开闪光灯");
    if (_cameraView.flashButton.selected == YES) {
        _cameraView.flashButton.selected = NO;
        //关闭闪光灯
        [_cameraView.flashButton setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
        [self setTorchMode:AVCaptureTorchModeOff];
    }else{
        _cameraView.flashButton.selected = YES;
        //开启闪光灯
        [_cameraView.flashButton setBackgroundImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
        [self setTorchMode:AVCaptureTorchModeOn];
    }


}
/****** 开始拍摄 *****/
- (void)cameraViewDidBeginShoot
{
    NSLog(@"开始拍摄");
    if (_currentTime >= _cameraTime) {
        [_cameraView.shootBtn stopAnimation];
    }
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[_camera.deviceVideoOutput connectionWithMediaType:AVMediaTypeVideo];
    // 开启视频防抖模式
    AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
    if ([_camera.videoCaptureDeviceInput.device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
        [captureConnection setPreferredVideoStabilizationMode:stabilizationMode];
    }
    
    //根据连接取得设备输出的数据
    if (![_camera.deviceVideoOutput isRecording]) {
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation=[_camera.videoPreviewLayer connection].videoOrientation;
        [_camera.deviceVideoOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[self getVideoSaveFilePathString]] recordingDelegate:self];
        [_camera startCamera];
        
        
    }
    else{
        [self stopTimer];
        [_camera.deviceVideoOutput stopRecording];//停止录制
    }

}

#pragma mark -- timer
-(void)startTimer{
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
                                              target:self
                                            selector:@selector(onTimer:)
                                            userInfo:nil
                                             repeats:YES];
    [_timer fire];
}

-(void)stopTimer{
    
    [_timer invalidate];
    _timer = nil;
    
}


- (void)onTimer:(NSTimer *)timer
{
    _currentTime += TIMER_INTERVAL;
    [self progressAddAnimation];
    //时间到了停止录制视频
    if (_currentTime>=self.cameraTime) {
        [_timer invalidate];
        _timer = nil;
        [_camera.deviceVideoOutput stopRecording];
        [_cameraView.shootBtn stopAnimation];
    }
    
}

/****** 结束拍摄 *****/
- (void)cameraViewDidEndShoot
{
    NSLog(@"结束拍摄");
  //  [_camera.deviceVideoOutput stopRecording];
    //正在拍摄
    if (_camera.deviceVideoOutput.isRecording) {
        [_camera.deviceVideoOutput stopRecording];
        [self stopTimer];
//        if (urlArray.count != 0) {
//            [self mergeAndExportVideosAtFileURLs:urlArray];
//        }

    }else{//已经暂停了
        
    }


}


/****** 即将取消拍摄 *****/
- (void)cameraViewWillCancelShootAction
{
    NSLog(@"即将取消拍摄");
   
    

}

#pragma mark --AVCaptureFileOutputRecordingDelegate
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self startTimer];
    
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"---- 录制结束 ----");

    [urlArray addObject:outputFileURL];

    //时间到了
   // if (_currentTime>=self.cameraTime) {
        [self mergeAndExportVideosAtFileURLs:urlArray];

   //}
}


#pragma mark - 私有方法
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

-(void)setTorchMode:(AVCaptureTorchMode )torchMode{
    [_camera changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isTorchModeSupported:torchMode]) {
            [captureDevice setTorchMode:torchMode];
        }
    }];
}


- (void)mergeAndExportVideosAtFileURLs:(NSMutableArray *)fileURLArray
{
    NSError *error = nil;
    
    CGSize renderSize = CGSizeMake(0, 0);
    
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    CMTime totalDuration = kCMTimeZero;
    
    NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
    NSMutableArray *assetArray = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileURLArray) {
        
        AVAsset *asset = [AVAsset assetWithURL:fileURL];
        [assetArray addObject:asset];
        
        NSArray* tmpAry =[asset tracksWithMediaType:AVMediaTypeVideo];
        if (tmpAry.count>0) {
            AVAssetTrack *assetTrack = [tmpAry objectAtIndex:0];
            [assetTrackArray addObject:assetTrack];
            renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.height);
            renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.width);
        }
    }
    
    CGFloat renderW = MIN(renderSize.width, renderSize.height);
    
    for (int i = 0; i < [assetArray count] && i < [assetTrackArray count]; i++) {
        
        AVAsset *asset = [assetArray objectAtIndex:i];
        AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
        
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSArray*dataSourceArray= [asset tracksWithMediaType:AVMediaTypeAudio];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:([dataSourceArray count]>0)?[dataSourceArray objectAtIndex:0]:nil
                             atTime:totalDuration
                              error:nil];
        
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:assetTrack
                             atTime:totalDuration
                              error:&error];
        
        AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        totalDuration = CMTimeAdd(totalDuration, asset.duration);
        
        CGFloat rate;
        rate = renderW / MIN(assetTrack.naturalSize.width, assetTrack.naturalSize.height);
        
        CGAffineTransform layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
        layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2.0+preLayerHWRate*(preLayerHeight-preLayerWidth)/2));
        layerTransform = CGAffineTransformScale(layerTransform, rate, rate);
        
        [layerInstruciton setTransform:layerTransform atTime:kCMTimeZero];
        [layerInstruciton setOpacity:0.0 atTime:totalDuration];
        
        [layerInstructionArray addObject:layerInstruciton];
    }
    
    NSString *path = [self getVideoMergeFilePathString];
    NSURL *mergeFileURL = [NSURL fileURLWithPath:path];
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruciton.layerInstructions = layerInstructionArray;
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.frameDuration = CMTimeMake(1, 100);
    mainCompositionInst.renderSize = CGSizeMake(renderW, renderW*preLayerHWRate);
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    exporter.videoComposition = mainCompositionInst;
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            _mergeFileURL = mergeFileURL;
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *path = [paths objectAtIndex:0];
            
            NSString *folderPath = [path stringByAppendingPathComponent:VIDEO_FOLDER];
            
            [self getFileSize:folderPath];

            [self getVideoLength:mergeFileURL];
//            PlayVideoViewController* view = [[PlayVideoViewController alloc]init];
//            view.videoURL =mergeFileURL;
//            [self.navigationController pushViewController:view animated:YES];
//            
        });
    }];
}


//此方法可以获取文件的大小，返回的是单位是KB。
/*
 NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
 NSString *path = [paths objectAtIndex:0];
 
 NSString *folderPath = [path stringByAppendingPathComponent:VIDEO_FOLDER];
 
 [self getFileSize:folderPath];
 
 
 */

- (CGFloat) getFileSize:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        if (error){
            NSLog(@"getfilesize error: %@", error);
            return NO;
        }
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024;
        NSLog(@"filesize = %fKB-----",filesize);
    }
    return filesize;
}

// 此方法可以获取视频文件的时长。

- (CGFloat) getVideoLength:(NSURL *)URL
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:URL options:opts];
    float second = 0;
    second = urlAsset.duration.value/urlAsset.duration.timescale;
    
    NSLog(@"second -----%f",second);
    return second;
}
//最后合成为 mp4
- (NSString *)getVideoMergeFilePathString
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];

    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@"merge.mp4"];
    
    return fileName;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
