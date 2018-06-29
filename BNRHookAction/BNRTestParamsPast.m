//
//  BNRTestParamsPast.m
//  BNRHookAction
//
//  Created by JustinYang on 2018/6/13.
//  Copyright © 2018年 JustinYang. All rights reserved.
//

#import "BNRTestParamsPast.h"
#import <objc/runtime.h>

typedef struct {
    long a;
    long b;
    float f;
    BOOL c;
} TestType;
@implementation BNRTestParamsPast
-(void)test{
    [self testParamsPast:1 :2 :3 :4 :5 :6 :7 :8 :9 :10];
    testCFunParamsPast(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    testVariadicFun((void *)0xAAAAAAAA, (void *)0x77777777,1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    Method m = class_getInstanceMethod([self class], NSSelectorFromString(@"testParamsPast::::::::::"));
    method_setImplementation(m, (IMP)testVariadicFun);
    [self testParamsPast:1 :2 :3 :4 :5 :6 :7 :8 :9 :10];
    
    method_setImplementation(m, (IMP)testVariadicFun2);
    [self testParamsPast:1 :2 :3 :4 :5 :6 :7 :8 :9 :10];

    Method m2 = class_getInstanceMethod([self class], NSSelectorFromString(@"testParamsPast1:::::::::::::::::"));
    method_setImplementation(m2, (IMP)testVariadicFun1);
    [self testParamsPast1:1.1 :2.2 :3.3 :4.4 :5.5 :6.6 :7.7 :8.8 :9.9 :10 :11 :YES :self :@"1" :2 :3 :0x04];
    
    Method m3 = class_getInstanceMethod([self class], NSSelectorFromString(@"testParamsPast2::::::::::::"));
    method_setImplementation(m3, (IMP)testVariadicFun3);
    [self testParamsPast2:1.1 :2.2 :3 :4 :5 :6 :7 :8 :9 :10 :11 :12.12];
}

/**
 * 对于arm64结构
 * 参数为double(float)时，参数会用d0(s0)-d7(s7),其他参数(包括那些不所占空间
 * 不需要64bit的参数)用x0-x7传递；超出寄存器个数的参数通过内存传递;
 */
-(void)testParamsPast:(long)a :(long)b :(long)c :(long)d :(long)e :(long)f :(long)g :(long)h :(long)i :(long)j{
    long localA = 0xffffffff;
    NSLog(@"%@",@(localA));
}

void testCFunParamsPast(long a,long b,long c, long d, long e, long f,long g, long h, long i, long j){
    long localA = 0xffffffff;
    NSLog(@"%@",@(localA));
}

void testVariadicFun(void * self, void * _cmd, ...){
    va_list args;
    va_start(args, _cmd);
    long param = va_arg(args, long);
    param = va_arg(args, long);
    param = va_arg(args, long);
    param = va_arg(args, long);
    param = va_arg(args, long);
    param = va_arg(args, long);
    param = va_arg(args, long);
    param = va_arg(args, long);
    param = va_arg(args, long);
    param = va_arg(args, long);
    va_end(args);
}
/**
 *  对于arm64，由于类型是void *,这里param1~param6都是从x2-x7取值的；如当被hook的
 *  OC函数第一个参数为float时，param1就取不到正确的float值了，
 */
void testVariadicFun2(void * self, void * _cmd,void *parm1,void *parm2,void *parm3,void *parm4,void *parm5,void *parm6, ...){
    va_list args;
    va_start(args, parm6);
    long param = va_arg(args, long);
    param = va_arg(args, long);
    param = va_arg(args, long);
    param = va_arg(args, long);
    va_end(args);
}
-(void)testParamsPast1:(float)a :(double)b :(float)c :(double)d :(float)e :(double)f :(float)g :(double)h :(double)i :(long)j :(long)k
                      :(BOOL)l :(id)n :(NSString *)m :(long)o :(UInt8)p :(UInt8)r{
    long localA = 0xffffffff;
    NSLog(@"%@",@(localA));
}

/**
 *  对hook arm64上的方法，用寄存器的方式来读取值，当x0-x7,d0(s0)-d7(s7)都存了
 *  参数后，在想用va_list从内存中取值，参数值或者参数值的地址是占8个字节时，
 *  取值没有问题，但是当参数值有float,unit8,结构体等时，就取不到正确的参数的值了
 *  (因为不是直接调用可变函数，存内存时，不会按照cpu的位数对齐)，例子中在最后两个参数
 *  不占8个字节，取不到正确值；
 *  所以BNRHookAction直接不hook超过传参寄存器个数参数的函数。
 *
 */
void testVariadicFun1(id self, SEL _cmd,...){
#if defined(__arm64__)
    float f0,f1,f2,f3,f4,f5,f6,f7;
    double d0,d1,d2,d3,d4,d5,d6,d7;
    long x0,x1,x2,x3,x4,x5,x6,x7;
    asm(
        "fmov   %w0,s0\n"
        "fmov   %8,d0\n"
        "fmov   %w1,s1\n"
        "fmov   %9,d1\n"
        "fmov   %w2,s2\n"
        "fmov   %10,d2\n"
        "fmov   %w3,s3\n"
        "fmov   %11,d3\n"
        "fmov   %w4,s4\n"
        "fmov   %12,d4\n"
        "fmov   %w5,s5\n"
        "fmov   %13,d5\n"
        "fmov   %w6,s6\n"
        "fmov   %14,d6\n"
        "fmov   %w7,s7\n"
        "fmov   %15,d7\n"
        :"=r"(f0),"=r"(f1),"=r"(f2),"=r"(f3),"=r"(f4),"=r"(f5),"=r"(f6),"=r"(f7),"=r"(d0),"=r"(d1),"=r"(d2),"=r"(d3),"=r"(d4),"=r"(d5),"=r"(d6),"=r"(d7)
        :
        :"x2","x3","x4","x5","x6","x7"
        );
    asm(
        "mov   %0,x2\n"
        "mov   %1,x3\n"
        "mov   %2,x4\n"
        "mov   %3,x5\n"
        "mov   %4,x6\n"
        "mov   %5,x7\n"
        :"=r"(x2),"=r"(x3),"=r"(x4),"=r"(x5),"=r"(x6),"=r"(x7)
        :
        :
        );
#endif
    va_list args;
    va_start(args, _cmd);
#if defined(__arm64__)
    Method originMethod = class_getInstanceMethod([self class], _cmd);
    unsigned int argsCount = method_getNumberOfArguments(originMethod);
    unsigned int pointParams = 0;
    for (int i = 2; i < argsCount; i++) {
        char *paramType = method_copyArgumentType(originMethod, i);
        if (strcmp(paramType, @encode(float)) == 0 ||
            strcmp(paramType, @encode(double)) == 0) {
            pointParams++;
        }
    }

#define kVar(type,num)  num==0?type##0:(num==1?type##1:(num==2?type##2:(num==3?type##3:(num==4?type##4:(num==5?type##5:(num==6?type##6:(num==7?type##7:0)))))))
    //最多只能从寄存器中去16个值
    int maxRegCount = (pointParams + 8)>16?16:(pointParams + 8);
    for (int i = 2, pointCount = 0,longCount = 2; i < argsCount; i++) {
        char *paramType = method_copyArgumentType(originMethod, i);
        if (i <= maxRegCount) { //从寄存器中取值
            if (strcmp(paramType, @encode(float)) == 0) {
                float value;
                if (pointCount < 8) {
                   value = kVar(f, pointCount);
                    pointCount++;
                }else{
                    //float时取不到正确的值
                    value = va_arg(args, float);
                    NSLog(@"%f",value);
                }
               
            }else if(strcmp(paramType, @encode(double)) == 0){
                double value;
                 if (pointCount < 8) {
                     value = kVar(d, pointCount);
                     pointCount++;
                 }else{
                     value = va_arg(args, double);
                     NSLog(@"%f",value);
                 }
                
            }else{
                long value;
                if (longCount < 8) {
                    value = kVar(x, longCount);
                    longCount++;
                }
            }
        }else{
            int value = va_arg(args, int);
            short value1 = va_arg(args, UInt16);
            NSLog(@"%l",value);
        }
    }
#endif
    va_end(args);
}


-(void)testParamsPast2:(float)a :(double)b :(UInt8)c  :(UInt8)d :(UInt8)e :(UInt8)f :(UInt8)g :(UInt8)h :(UInt8)i :(UInt8)j :(UInt8)k :(double)x{
    
}
void testVariadicFun3(id self, SEL _cmd,...){
#ifndef __arm64__
    va_list ap;
    va_start(ap, _cmd);
    float f = va_arg(ap, float);
    f = va_arg(ap, double);
    int  c = va_arg(ap, int);
    c = va_arg(ap, int);
    c = va_arg(ap, int);
    c = va_arg(ap, int);
    c = va_arg(ap, int);
    c = va_arg(ap, int);
    c = va_arg(ap, int);
    c = va_arg(ap, int);
    c = va_arg(ap, int);
    f = va_arg(ap, double);
    va_end(ap);
#endif
}
@end
