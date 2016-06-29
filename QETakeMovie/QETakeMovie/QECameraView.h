//
//  QECameraView.h
//  QETakeMovie
//
//  Created by user on 16/6/24.
//  Copyright © 2016年 mobin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QEShootButton.h"

@class QECameraView;
@protocol QECameraViewDelegate <NSObject>

@optional
/****** 交换摄像头 *****/
- (void)cameraViewDidChangeCarame:(UIButton *)cameraButton;
/****** 打开闪光灯 *****/
- (void)cameraViewDidOpenFlash:(UIButton *)falshButton;
/****** 开始拍摄 *****/
- (void)cameraViewDidBeginShoot;
/****** 结束拍摄 *****/
- (void)cameraViewDidEndShoot;
/****** 即将取消拍摄 *****/
- (void)cameraViewWillCancelShootAction;

@end
@interface QECameraView : UIView
@property (nonatomic,weak) UIView *preView; //camareView
@property (nonatomic,weak) id<QECameraViewDelegate> delegate;
@property (nonatomic,weak)  UIView *progressView; //拍摄进度条
@property (nonatomic,weak)  QEShootButton *shootBtn;  //拍摄按钮
@property (nonatomic,weak)     UIButton *flashButton; //闪光灯
@property (nonatomic,weak)   UIButton *changeCameraBtn; //改变摄像头 ;
@end
