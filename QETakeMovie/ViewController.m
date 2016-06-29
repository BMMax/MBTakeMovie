//
//  ViewController.m
//  QETakeMovie
//
//  Created by user on 16/6/24.
//  Copyright © 2016年 mobin. All rights reserved.
//

#import "ViewController.h"
#import "QETakeMovieViewController.h"

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)takeMovie:(UIButton *)sender {
    
   UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:({
        QETakeMovieViewController *vc = [[QETakeMovieViewController alloc]init];
        vc;
    })];

    [self presentViewController:nav animated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
