//
//  MBCamera.m
//  QETakeMovie
//
//  Created by user on 16/6/26.
//  Copyright © 2016年 mobin. All rights reserved.
//

#import "MBCamera.h"


typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);
@interface MBCamera()
@property (strong,nonatomic)  UIImageView *focusCursor; //聚焦光标

@end

@implementation MBCamera
-(instancetype)init{
    if (self = [super init]) {
        
        
        //一，初始化输入设备，这里涉及到前，后摄像头;麦克风(导入AVFoundation)
        //1.创建视频设备(摄像头前，后)
        //_videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        _videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头

        // 2.添加一个音频输入设备 ,直接可以拿数组中的数组中的第一个
        _audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
        
        // 3.视频输入对象,根据输入设备初始化输入对象，用户获取输入数据
        // 3.1 初始化一个摄像头输入设备(first是后置摄像头，last是前置摄像头)
        NSError *error = nil;
        _videoCaptureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_videoCaptureDevice error:&error];
        if (error) {
            NSLog(@"---- 取得设备输入对象时出错 ------ %@",error);
        }
        // 3.2音频输入对象
        //根据输入设备初始化设备输入对象，用于获得输入数据
        _audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:_audioCaptureDevice error:&error];
        if (error) {
            NSLog(@"取得设备输入对象时出错 ------ %@",error);
        }
        // 二，初始化视频文件输出
        //初始化输出设备对象，用户获取输出数据
        _deviceVideoOutput = [[AVCaptureMovieFileOutput alloc]init];
        //三,初始化会话，并将输入输出设备添加到会话中
        _session = [[AVCaptureSession alloc]init];
        if ([_session canAddOutput:_deviceVideoOutput]) {
            [_session addOutput:_deviceVideoOutput];
        }
        //分辨率
        if ([_session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            [_session setSessionPreset:AVCaptureSessionPreset640x480];
        }
        //3.1将视频输入对象添加到会话中
        if ([_session canAddInput:_videoCaptureDeviceInput]) {
            [_session addInput:_videoCaptureDeviceInput];
        }
        //3.2讲音频输入对象添加会话中
        if ([_session canAddInput:_audioCaptureDeviceInput]) {
            [_session addInput:_audioCaptureDeviceInput];
            AVCaptureConnection *captureConnection = [_deviceVideoOutput connectionWithMediaType:AVMediaTypeVideo];
            // 标识视频录入时稳定音频流的接受，我们这里设置为自动
            if ([captureConnection isVideoStabilizationSupported]) {
                captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
        }


        // 四.配置默认帧数1秒10帧
        [_session beginConfiguration];
        if ([_videoCaptureDevice lockForConfiguration:&error]) {
            [_videoCaptureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 10)];
            [_videoCaptureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 10)];
            [_videoCaptureDevice unlockForConfiguration];
        }
        [_session commitConfiguration];
        [self focusAtPoint:_preView.center];
        
        
        
    }
    return self;
}

//获取摄像头
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{

    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

//预览层嵌入
-(void)embedLayerWithView:(UIView *)view{
    _preView = view;
    if (_session == nil) {
        return;
    }
    self.focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 50, 50)];
    [self.focusCursor setImage:[UIImage imageNamed:@"focusImg"]];
    self.focusCursor.alpha = 0;
    [view addSubview:self.focusCursor];
    
    
    //四 通过会话 (AVCaptureSession) 创建预览层
    _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    //设置layer大小
    _videoPreviewLayer.frame = view.layer.bounds;
    //layer填充状态
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //设置摄像头朝向
    _videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [view.layer insertSublayer:_videoPreviewLayer below:self.focusCursor.layer];
    //创建对焦手势
    [self addGenstureRecognizerInView:view];
}

- (void)addGenstureRecognizerInView:(UIView *)genstureRecognizerView
{

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToFocus:)];
    [genstureRecognizerView addGestureRecognizer:tapGesture];

}
//点击手势响应方法
-(void)tapToFocus:(UITapGestureRecognizer*)gestureRecognizer{
    
    CGPoint point = [gestureRecognizer locationInView:_preView];
    //讲UI坐标转换成摄像头坐标
    CGPoint cameraPoint = [_videoPreviewLayer captureDevicePointOfInterestForPoint:point];
    
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus
           exposureMode:AVCaptureExposureModeAutoExpose
                atPoint:cameraPoint];
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

-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= [_videoCaptureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}


//设置自动对焦
-(void)focusAtPoint:(CGPoint)point{
    if ([_videoCaptureDevice isFocusPointOfInterestSupported] && [_videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error = nil;
        if ([_videoCaptureDevice lockForConfiguration:&error]) {
            [_videoCaptureDevice setFocusPointOfInterest:point];
            [_videoCaptureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [_videoCaptureDevice unlockForConfiguration];
        }
    }
}
//设置连续对焦
-(void)continuousFocusAtPoint:(CGPoint)point{
    if ([_videoCaptureDevice isFocusPointOfInterestSupported] && [_videoCaptureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSError *error = nil;
        if ([_videoCaptureDevice lockForConfiguration:&error]) {
            [_videoCaptureDevice setFocusPointOfInterest:point];
            [_videoCaptureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [_videoCaptureDevice unlockForConfiguration];
        }
    }
}

//配置自定义拍摄帧数
- (void)setFrameNum:(NSInteger)frameNum{
    _frameNum = frameNum;
    [_session beginConfiguration];
    NSError *error;
    if ([_videoCaptureDevice lockForConfiguration:&error]) {
        [_videoCaptureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, (int)_frameNum)];
        [_videoCaptureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, (int)_frameNum)];
        [_videoCaptureDevice unlockForConfiguration];
    }
    [_session commitConfiguration];
}
//开始拍摄
-(void)startCamera{
    // 让会话（AVCaptureSession）勾搭好输入输出，然后把视图渲染到预览层上
    [_session startRunning];
}
//停止拍摄
-(void)stopCamera{
    [_session stopRunning];
}

@end
