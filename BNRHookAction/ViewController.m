//
//  ViewController.m
//  BNRHookAction
//
//  Created by JustinYang on 2017/8/26.
//  Copyright © 2017年 JustinYang. All rights reserved.
//

#import "ViewController.h"

#import "FatherVC.h"
#import "BNRTestParamsPast.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    NSLog(@"🌺输出hook信息");
    
    [self testFuncWithOutParams];
    [self testFuncWithId:@"id type"];
    NSLog(@"return value of testFuncWithBaseParam:%@",@([self testFuncWithBaseParam:10]));
    
    NSLog(@"return value of testFuncWithParam0:andParam1:%@",[self testFuncWithParam0:@[@44] andParam1:YES]);
    [self testFuncWithBlock:^(BOOL flag) {
        NSLog(@"called block whit param :%@",@(flag));
    }];
    
    [ViewController classMethod];
    [self testFunc:1.1 :2.2 :0x03 :@"string" :0x0101];
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

+(void)classMethod{
    NSLog(@"%s",__func__);
}
-(NSString *)testFunc:(float)f :(double)d :(UInt8)c :(NSString *)obj :(UInt16)s{
    NSLog(@"%s,%f,%f,%d,%@,%d",__func__,f,d,c,obj,s);
    return @"return string";
}
-(void)block:(void (^)(void (^block)(NSString *a)))test{
    void (^block)(NSString *a) = ^(NSString *a){
        NSLog(@"%@",a);
    };
    !test?:test(block);
}
- (IBAction)pushFatherVC:(id)sender {
    FatherVC *vc = [FatherVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSLog(@"%s",__func__);
}
- (IBAction)testDeliveryParam:(id)sender {
    BNRTestParamsPast *obj = [BNRTestParamsPast new];
    [obj test];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
