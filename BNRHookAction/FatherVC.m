//
//  FatherVC.m
//  BNRHookAction
//
//  Created by JustinYang on 2017/9/2.
//  Copyright © 2017年 JustinYang. All rights reserved.
//

#import "FatherVC.h"
#import "ChildVC.h"
#import "ChildVC1.h"
@interface FatherVC ()

@end

@implementation FatherVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"下一个界面" style:UIBarButtonItemStylePlain target:self action:@selector(nextVC)];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[self class] classMethod:@"class method param"];
    [self printSomething];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"ChildVC1" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btn sizeToFit];
    btn.center = self.view.center;
    [btn addTarget:self action:@selector(pushChildVC1) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
-(void)pushChildVC1{
    ChildVC1 *vc = [ChildVC1 new];
    [self.navigationController pushViewController:vc animated:YES];
}
-(void)printSomething{
    NSLog(@"father printSomething");
}
-(void)backAction{
    NSLog(@"Father pop");
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)nextVC{
    ChildVC *vc = [[ChildVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+(void)classMethod:(NSString *)param{
    NSLog(@"%@",param);
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
