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
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"record" ofType:@"plist"];
    NSDictionary *recordDic = [NSDictionary dictionaryWithContentsOfFile:path];
    [[BNRHookAction shareInstance] setRecordDic:recordDic
                                   andHookBlock:^(NSString *target, NSString *action, NSDictionary *handleDic) {
                                       NSLog(@"xxxx--%@",action);
                                   }];
    
    [self testFuncWithOutParams];
    [self testFuncWithId:@"我是一个id类型"];
    NSLog(@"testFuncWithBaseParam 的返回值是:%@",@([self testFuncWithBaseParam:10]));
    
    NSLog(@"testFuncWithParam0:andParam1: 的返回值是:%@",[self testFuncWithParam0:@[@1,@2] andParam1:YES]);
    [self testFuncWithBlock:^(BOOL flag) {
        NSLog(@"我是回调block %@",@(flag));
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
    //    return flag?@"返回YES":@"返回NO";
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
