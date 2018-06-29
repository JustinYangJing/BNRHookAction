//
//  ChildVC2.m
//  BNRHookAction
//
//  Created by JustinYang on 2017/9/2.
//  Copyright © 2017年 JustinYang. All rights reserved.
//

#import "ChildVC2.h"

@interface ChildVC2 ()

@end

@implementation ChildVC2

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItems = @[];
    [self printSomething];
}
-(void)printSomething{
    [super printSomething];
    NSLog(@"ChildVC2 printSomething");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//-(void)backAction{
//    NSLog(@"Child pop");
//    [self.navigationController popViewControllerAnimated:YES];
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
