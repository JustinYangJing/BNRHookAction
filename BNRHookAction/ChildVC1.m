//
//  ChildVC1.m
//  BNRHookAction
//
//  Created by JustinYang on 2017/9/3.
//  Copyright © 2017年 JustinYang. All rights reserved.
//

#import "ChildVC1.h"

@interface ChildVC1 ()

@end

@implementation ChildVC1

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItems = @[];
    [self printSomething];
}
-(void)printSomething{
    [super printSomething];
    NSLog(@"ChildVC1 printSomething");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
