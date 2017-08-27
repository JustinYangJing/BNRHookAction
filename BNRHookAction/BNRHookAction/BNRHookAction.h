//
//  BNRHookAction.h
//  BNRHookAction
//
//  Created by JustinYang on 2017/8/25.
//  Copyright © 2017年 JustinYang. All rights reserved.
//  https://github.com/JustinYangJing/BNRHookAction.git

#import <Foundation/Foundation.h>

@interface BNRHookAction : NSObject
/**
 *  需要hook函数的字典，外面的类不需要访问他，因为在C函数里面访问他，才公开出来的
 */
@property (nonatomic,readonly,copy)NSDictionary *recordDic;

/**
 *  hook的block,hook后的函数，会先调用这个block,再调用原函数
 */
@property (nonatomic,copy) void (^hookBlock)(NSString *target,NSString *action,NSDictionary *handleDic);

/**
 *  类方法
 *
 *  @return 返回BNRHookAction实例
 */
+(BNRHookAction *)shareInstance;

/**
 *  设置hook字典和hook block,
 *
 *  @param recordDic   hook字典
 *  {"ClassName1":{
                "actionName1":{
                    "key1":"value1";
                    "key2":"value2"};
                 "actionName2":{
                 "key1":"value1";
                 "key2":"value2"}
                };
     "ClassName1":{
                 "actionName1":{
                 "key1":"value1";
                 "key2":"value2"};
                 "actionName2":{
                 "key1":"value1";
                 "key2":"value2"}
                 }
    }
 *  想要hook className下的actionName方法，className标示类名，actionName标示函数名，
 *  源码会根据这两个key值去hook。key1和value1，您可以自定义，比如做统计时,以eventId为key,
 *  在友盟或百度统计平台上自定义的事件Id为value,只要在传进来的block里面调用[MobClick event:value]
 *  就能做无侵入式埋点了，hook字典可以用后台下发。value也可以为block，调用您事先定义好的block
 *
 *  @param handleBlock hook Block，
 *  hook参数 target：hook的是那个类， aciton:hook的那个函数，handleDic：
 *  {"key1":"value1";"key2":"value2"}，之前传入的字典。
 */
-(void)setRecordDic:(NSDictionary *)recordDic andHookBlock:(void (^)(NSString *target,
                                                                     NSString *action,
                                                                     NSDictionary *handleDic))handleBlock;
@end
