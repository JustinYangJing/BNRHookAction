//
//  ViewController.m
//  BNRHookAction
//
//  Created by JustinYang on 2017/8/26.
//  Copyright © 2017年 JustinYang. All rights reserved.
//

#import "ViewController.h"
#import "BNRHookAction.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
       
    [self testFuncWithOutParams];
    [self testFuncWithId:@"id type"];
    NSLog(@"return value of testFuncWithBaseParam:%@",@([self testFuncWithBaseParam:10]));
    
    NSLog(@"return value of testFuncWithParam0:andParam1:%@",[self testFuncWithParam0:@[@1,@2] andParam1:YES]);
    [self testFuncWithBlock:^(BOOL flag) {
        NSLog(@"called block whit param :%@",@(flag));
    }];
    [ViewController classMethod];
    [self noHookFunc];

}

-(void)testFuncWithOutParams{
    NSLog(@"%s",__func__);
}
-(void)testFuncWithId:(id)param{
    NSLog(@"%s %@",__func__,param);
}
-(int)testFuncWithBaseParam:(int)num{
    NSLog(@"%s %@",__func__,@(num));
    return num+1;
}

-(id)testFuncWithParam0:(NSArray *)param0 andParam1:(BOOL)flag{
    NSLog(@"%s %@ %@",__func__,param0,@(flag));
    return nil;
}
-(void)testFuncWithBlock:(void (^)(BOOL flag))block{
    NSLog(@"%s %@",__func__,block);
    !block?:block(YES);
}
-(void)noHookFunc{
    NSLog(@"%s",__func__);
}
+(void)classMethod{
    NSLog(@"%s",__func__);
}
-(void)block:(void (^)(void (^block)(NSString *a)))test{
    void (^block)(NSString *a) = ^(NSString *a){
        NSLog(@"%@",a);
    };
    !test?:test(block);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
