//
//  QEShootButton.m
//  QETakeMovie
//
//  Created by user on 16/6/25.
//  Copyright © 2016年 mobin. All rights reserved.
//

#import "QEShootButton.h"
#import "Masonry.h"
@interface QEShootButton()<UIGestureRecognizerDelegate>

@property (nonatomic,strong) CAShapeLayer *circleLayer;
@property (nonatomic,strong) CAShapeLayer *backCircleLayer;
@property (nonatomic,strong) UILabel *textLabel;
@property (nonatomic,strong) UILabel *cancelLabel;
@property (nonatomic,assign,getter=isShootThoughlongPressGestureRecognizer) BOOL shootThoughlongPressGestureRecognizer;
//@property (nonatomic,strong) UILongPressGestureRecognizer *longPresGes; //长按拍摄按钮
//@property (nonatomic,strong) UIPanGestureRecognizer *panGes; //拍摄按钮

@end



@implementation QEShootButton

- (UILabel *)cancelLabel
{
    if (!_cancelLabel) {
        _cancelLabel = [[UILabel alloc]init];
        _cancelLabel.text = @"松开取消";
        _cancelLabel.backgroundColor = [UIColor redColor];
        _cancelLabel.textColor = [UIColor whiteColor];
        _cancelLabel.frame = CGRectMake(0, 0, 60, 30);
        _cancelLabel.textAlignment = NSTextAlignmentCenter;
        _cancelLabel.font = [UIFont systemFontOfSize:12];
        _cancelLabel.alpha = 0.7;
    }
    return _cancelLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _circleLayer = [CAShapeLayer layer];
       [self.layer addSublayer:_circleLayer];
        _backCircleLayer = [CAShapeLayer layer];
        [self.layer addSublayer:_backCircleLayer];
        
        _textLabel = ({
            UILabel *label = [[UILabel alloc]init];
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor blackColor];
            label.text = @"按住拍";
            label.textAlignment = NSTextAlignmentCenter;
            [label setFont:[UIFont systemFontOfSize:15]];
            label;
        });
       
         [self addSubview:_textLabel];
        [_textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(self);
        }];
        
        // 长按拍摄
        UILongPressGestureRecognizer *longGes = [[UILongPressGestureRecognizer alloc]initWithTarget:self
                                                                                             action:@selector(startShootAction:)];
        longGes.minimumPressDuration = 0.2;
        longGes.delegate = self ;
        [self addGestureRecognizer:longGes];
        // 上移 取消
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self
                                                                             action:@selector(panCancelAction:)];
        pan.delegate = self;
        [self addGestureRecognizer:pan];
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    // UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:_circleLayer.position radius:self.frame.size.width * 0.5 startAngle:-M_PI endAngle:M_PI clockwise:YES];
    _circleLayer.frame = self.bounds;
    _backCircleLayer.frame = CGRectMake(0, 0, self.bounds.size.width-9, self.bounds.size.height-9);
    UIBezierPath *path1 = [UIBezierPath bezierPathWithArcCenter:_circleLayer.position radius:self.frame.size.width/2 startAngle:-M_PI endAngle:M_PI clockwise:YES];
    UIBezierPath *path2 = [UIBezierPath bezierPathWithArcCenter:_circleLayer.position radius:(self.frame.size.width-9)/2 startAngle:-M_PI endAngle:M_PI clockwise:YES];
    _circleLayer.path = path1.CGPath;
    _backCircleLayer.path = path2.CGPath;
    _circleLayer.fillColor = [UIColor clearColor].CGColor;
    _backCircleLayer.fillColor = [UIColor blackColor].CGColor;
    _circleLayer.lineWidth = 1;
    _circleLayer.strokeColor = [UIColor blackColor].CGColor;
    
}


- (void)setCircleStrokeColor:(UIColor *)circleStrokeColor
{
    _circleStrokeColor = circleStrokeColor;
    _circleLayer.strokeColor = circleStrokeColor.CGColor;
}


#pragma mark --gesAction
- (void)startShootAction:(UILongPressGestureRecognizer *)gestureRecognizer
{
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
      //  NSLog(@"拍摄开始");
        //长按拍摄开始
        [self appearAnimation];
        self.shootThoughlongPressGestureRecognizer = YES;
        if ([self.delegate respondsToSelector:@selector(shootButtonDidBeginShootAction)]) {
            [self.delegate shootButtonDidBeginShootAction];
        }
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
      //  NSLog(@"拍摄取消");
        //拍摄取消
        self.shootThoughlongPressGestureRecognizer = NO;
        [_circleLayer removeAllAnimations];
        if (_cancelLabel) {
            [_cancelLabel removeFromSuperview];
            _cancelLabel = nil;
        }
        
        if ([self.delegate respondsToSelector:@selector(shootButtonDidEndShootAction)]) {
            [self.delegate shootButtonDidEndShootAction];
        }
    }
    


}

- (void)panCancelAction:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self];
  // NSLog(@"-------point-------%@",NSStringFromCGPoint(point));
    if (point.y < 0) {
     //   NSLog(@"松开取消");
        // 松开取消拍摄
        if (self.isShootThoughlongPressGestureRecognizer) {
            [self addSubview:self.cancelLabel];
            self.cancelLabel.transform =CGAffineTransformMakeTranslation(15, point.y - 60);
            if ([self.delegate respondsToSelector:@selector(shootButtonWillCancelShootAction)]) {
                [self.delegate shootButtonWillCancelShootAction];
            }
        }
    }
    else{
        NSLog(@"上移取消");
    }
}


-(void)appearAnimation{
    CABasicAnimation *animation_scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation_scale.toValue = @1.5;
    CABasicAnimation *animation_opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation_opacity.toValue = @0;
    CAAnimationGroup *aniGroup = [CAAnimationGroup animation];
    aniGroup.duration = 0.5;
    aniGroup.animations = @[animation_scale,animation_opacity];
    aniGroup.fillMode = kCAFillModeForwards;
    aniGroup.repeatCount = HUGE_VALF;
    aniGroup.removedOnCompletion = NO;
    aniGroup.autoreverses = YES;
    [_circleLayer addAnimation:aniGroup forKey:@"start"];
}

#pragma mark -- UIGestureRecognizerDelegate 同时识别出两种手势
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognize
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;

}

- (void)stopAnimation
{
    [_circleLayer removeAnimationForKey:@"start"];

}

@end
