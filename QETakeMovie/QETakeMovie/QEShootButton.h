//
//  QEShootButton.h
//  QETakeMovie
//
//  Created by user on 16/6/25.
//  Copyright © 2016年 mobin. All rights reserved.
//

#import <UIKit/UIKit.h>


@class QEShootButton;
@protocol QEShootButtonDelegate <NSObject>
@optional
- (void)shootButtonDidBeginShootAction; //开始拍摄
- (void)shootButtonDidEndShootAction; //结束拍摄
- (void)shootButtonWillCancelShootAction; // 即将取消拍摄
@end

@interface QEShootButton : UIView

@property (nonatomic,strong) UIColor *circleStrokeColor; //圈圈颜色
@property (nonatomic,weak) id<QEShootButtonDelegate> delegate;
- (void)stopAnimation;
@end
