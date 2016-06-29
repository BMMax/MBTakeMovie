//
//  QECameraView.m
//  QETakeMovie
//
//  Created by user on 16/6/24.
//  Copyright © 2016年 mobin. All rights reserved.
//

#import "QECameraView.h"
#import "Masonry.h"
#import "UIView+Tools.h"
#import "QEShootButton.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface QECameraView()<QEShootButtonDelegate>
{
    UIButton *flashButton; //闪光灯
    UIButton *changeCameraBtn; //改变摄像头
   // UIButton *shootBtn; //拍摄按钮
    NSTimer *countTimer; //计时器
    UIView *progressViewBorder; //边框
    
}

@end
@implementation QECameraView


- (instancetype)initWithFrame:(CGRect)frame
{

    self = [super initWithFrame: frame];
    if (self) {
        [self mb_addAndLayoutSubviews];
    }
    return self;
}

#pragma mark --init
- (void)mb_addAndLayoutSubviews
{
    
    // 4 camareView
    UIView *camare = ({
        UIView *view = [[UIView alloc]init];
        view;
    });
    self.preView = camare;
    [self addSubview:camare];

    
    // 1.摄像头
    UIButton *cameraBtn = ({
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setBackgroundImage:[UIImage imageNamed:@"changeCamer"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(changeCameraTap:) forControlEvents:UIControlEventTouchUpInside];
        btn;
    });
    
    changeCameraBtn = cameraBtn;
    [self addSubview:cameraBtn];
    
    // 2.闪光灯
    UIButton *flashBtn = ({
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(flashButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        btn;
    });
    flashButton = flashBtn;
    [self addSubview:flashBtn];
    
    //底部按钮view
    UIView *bottomView = [[UIView alloc]init];
    bottomView.backgroundColor = [UIColor  whiteColor];
    [self addSubview:bottomView];
    
    // 3进度条边框
    UIView *progrossPreView = ({
        UIView *view = [[UIView alloc]init];
        view.layer.borderWidth = 1.0f;
        view.layer.borderColor = UIColorFromRGB(0x000000).CGColor;
        view;
    });
    progressViewBorder = progrossPreView;
    [bottomView addSubview:progrossPreView];
    //进度条
    UIView *progrossBorder = ({
        UIView *view = [[UIView alloc]init];
        view.backgroundColor = [UIColor blackColor];
        view;
    });
    self.progressView = progrossBorder;
    [bottomView addSubview:progrossBorder];
    
    
    /****** 拍摄按钮 *****/
    QEShootButton *Btn = ({
        QEShootButton *btn = [[QEShootButton alloc]init];
        btn.delegate = self;
        btn;
    });

    self.shootBtn = Btn;
    [self addSubview:Btn];
    //layout
    // 1.摄像头
    CGFloat cameraBtnTop = 17.0;
    CGFloat cameraBtnRight = 16.0;
    CGFloat cameraBtnWight = 34.0;
    CGFloat cameraBtnHeight = cameraBtnWight;
    [cameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.mas_top).offset(cameraBtnTop);
        make.right.mas_equalTo(self.mas_right).offset(-cameraBtnRight);
        make.width.mas_equalTo(cameraBtnWight);
        make.height.mas_equalTo(cameraBtnHeight);
    }];
    
    // 2.闪光灯
    CGFloat flashBtnRight = 19.0;
    CGFloat flashBtnWidth = cameraBtnHeight;
    [flashButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(cameraBtn);
        make.right.mas_equalTo(cameraBtn.mas_left).offset(-flashBtnRight);
        make.top.mas_equalTo(cameraBtn.mas_top);
    }];
    

    // 3 拍摄底部
    [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self);
        make.height.mas_equalTo(self.mas_height).multipliedBy(0.5);
    }];
    
    // camareView
    [camare mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(self);
        make.bottom.mas_equalTo(bottomView.mas_top);
    }];
    // 4 拍摄按钮
    CGFloat shootBtnWH = 177 * 0.5;
    [self.shootBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(bottomView);
        make.height.width.mas_equalTo(shootBtnWH);
    }];

    // 5 进度条
    CGFloat progressHeight= 8.f;
    [progressViewBorder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(bottomView);
        make.height.mas_equalTo(progressHeight);
    }];
    // 6 切圆角
    [flashButton makeCornerRadius:flashBtnWidth * 0.5 borderColor:nil borderWidth:0];
    [cameraBtn makeCornerRadius:cameraBtnHeight * 0.5 borderColor:nil borderWidth:0];
  //  [shootBtn makeCornerRadius:shootBtnWH * 0.5 borderColor:[UIColor blackColor] borderWidth:3];
    
    
   

}

#pragma mark --buttonTopAction
-(void)changeCameraTap:(UIButton *)sender
{
    NSLog(@"---------点击camera");
    if ([self.delegate respondsToSelector:@selector(cameraViewDidChangeCarame:)]) {
        [self.delegate cameraViewDidChangeCarame:sender];
    }
}

- (void)flashButtonTap:(UIButton *)sender
{
    NSLog(@"------点击闪光灯");
    if ([self.delegate respondsToSelector:@selector(cameraViewDidOpenFlash:)]) {
        [self.delegate cameraViewDidOpenFlash:sender];
    }


}

#pragma mark --QEShootButtonDelegate
- (void)shootButtonDidBeginShootAction //开始拍摄
{
    NSLog(@"开始拍摄");
    if ([self.delegate respondsToSelector:@selector(cameraViewDidBeginShoot)]) {
        [self.delegate cameraViewDidBeginShoot];
    }
}
- (void)shootButtonDidEndShootAction //结束拍摄
{
    NSLog(@"结束拍摄");
    if ([self.delegate respondsToSelector:@selector(cameraViewDidEndShoot)]) {
        [self.delegate cameraViewDidEndShoot];
    }
    
}
- (void)shootButtonWillCancelShootAction // 即将取消拍摄
{
    
    NSLog(@"即将取消拍摄");
    if ([self.delegate respondsToSelector:@selector(cameraViewWillCancelShootAction)]) {
        [self.delegate cameraViewWillCancelShootAction];
    }
}


@end
