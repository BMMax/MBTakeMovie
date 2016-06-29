//
//  MBCamera.h
//  QETakeMovie
//
//  Created by user on 16/6/26.
//  Copyright © 2016年 mobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface MBCamera : NSObject
{
    //会话层
    //创建 配置输入设备
    AVCaptureDevice *_videoCaptureDevice;
    AVCaptureDevice *_audioCaptureDevice;
    //显示层
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
 //   UIView *focusView;
}

@property (nonatomic,strong) AVCaptureSession *session; //负责输入和输出设置之间的数据传递
@property (nonatomic,strong) AVCaptureDeviceInput *videoCaptureDeviceInput;
@property (nonatomic,strong) AVCaptureDeviceInput *audioCaptureDeviceInput;
@property (nonatomic,strong) AVCaptureMovieFileOutput *deviceVideoOutput; //视频输出流
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic,strong) UIView *preView;
@property (nonatomic,assign) NSInteger frameNum;
//开始拍摄
-(void)startCamera;
//停止拍摄
-(void)stopCamera;
//预览层嵌入
-(void)embedLayerWithView:(UIView *)view;
//改变设备属性
- (void)changeDeviceProperty:(PropertyChangeBlock)propertyChange;

@end
