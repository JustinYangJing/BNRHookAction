//
//  BNRHookAction.m
//  BNRHookAction
//
//  Created by JustinYang on 2017/8/25.
//  Copyright © 2017年 JustinYang. All rights reserved.
//

#import "BNRHookAction.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface BNRHookAction ()

@end
@implementation BNRHookAction
{
    dispatch_queue_t _serialQueue;
}

+(BNRHookAction *)shareInstance{
    static dispatch_once_t onceToken;
    static BNRHookAction *hook;
    dispatch_once(&onceToken, ^{
        hook = [[BNRHookAction alloc] init];

    });
    return hook;
}

#pragma mark - private method
-(instancetype)init{
    self = [super init];
    if (self) {
        _serialQueue = dispatch_queue_create("hook serial queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
-(void)setRecordDic:(NSDictionary *)recordDic
       andHookBlock:(void (^)(NSString *target,
                              NSString *action,
                              NSDictionary *handleDic,
                              NSDictionary *params))handleBlock{
   
    _recordDic = recordDic;
    self.hookBlock = handleBlock;
    dispatch_async(_serialQueue, ^{
        NSArray *allKeys = self.recordDic.allKeys;
        for (NSString *className in allKeys) {
            NSDictionary *actionDic = self.recordDic[className];
            Class classInstance = NSClassFromString(className);
            NSArray *actionKeys = actionDic.allKeys;
            for (NSString *actionName in actionKeys) {
                Method originMethod = class_getInstanceMethod(classInstance, NSSelectorFromString(actionName));
                if (originMethod) {
                    Class classImplenmentThisInstanceMethod = getClassThatImplementThisMethod(classInstance, originMethod);
                    class_addMethod(classImplenmentThisInstanceMethod,
                                    NSSelectorFromString([NSString stringWithFormat:@"bnrHook_%@",actionName]),
                                    method_getImplementation(originMethod),
                                    method_getTypeEncoding(originMethod));
                    method_setImplementation(originMethod, (IMP)hookFunc);
                }else{
                    originMethod = class_getClassMethod(classInstance, NSSelectorFromString(actionName));
                    if (originMethod) {
                        Class metaClass = objc_getMetaClass(class_getName(classInstance));
                        Class metaClassImplenmentThisClassMethod = getClassThatImplementThisMethod(metaClass,originMethod);
                        class_addMethod(metaClassImplenmentThisClassMethod,
                                        NSSelectorFromString([NSString stringWithFormat:@"bnrHook_%@",actionName]),
                                        method_getImplementation(originMethod),
                                        method_getTypeEncoding(originMethod));
                        method_setImplementation(originMethod, (IMP)hookFunc);
                    }
                    
                }
                
            }
            
        }

    });
}

/**
 *  所有需要hook并需要调用源函数的函数都hook到了这个方法
 */
void* hookFunc(id self, SEL _cmd,...){
    BNRHookAction *record = [BNRHookAction shareInstance];
    NSString *className = NSStringFromClass([self class]);
    NSDictionary *actionDic = record.recordDic[className];
    NSString *actionName = NSStringFromSelector(_cmd);
    NSDictionary *actionInfo = actionDic[actionName];
    //hook表里面存放的是父类名字和父类action,那么子类调用这个action时，
    //需要把父类的action下的字典丢出去
    if (actionInfo == nil) {
        Class fatherClass = [self class];
        while (fatherClass) {
            Class tmpClass = class_getSuperclass(fatherClass);
            NSDictionary *tmpActionDic = record.recordDic[NSStringFromClass(tmpClass)];
            actionInfo = tmpActionDic[actionName];
            if (actionInfo == nil) {
                fatherClass = tmpClass;
            }else{
                break;
            }
        }
    }
    
    SEL hookSelect = NSSelectorFromString([NSString stringWithFormat:@"bnrHook_%@",NSStringFromSelector(_cmd)]);

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"self"] = self;
    params[@"_cmd"] = NSStringFromSelector(_cmd);
    if ([self respondsToSelector:hookSelect]) {
        
        NSMethodSignature *methodSig = [self methodSignatureForSelector:hookSelect];
        if (methodSig == nil) {
            return nil;
        }
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        
        Method originMethod = class_getInstanceMethod([self class], _cmd);
        if (originMethod == nil) {
            originMethod = class_getClassMethod(self, _cmd);
        }
        unsigned int argsCount = method_getNumberOfArguments(originMethod);
        va_list args;
        va_start(args, _cmd);
        
        
        for (int i = 2; i < argsCount; i++) {
            char *paramType = method_copyArgumentType(originMethod, i);
            id param = setInvocationParam(invocation, i, args, paramType);
            params[[NSString stringWithFormat:@"%@",@(i-2)]] = param;
            
        }
        va_end(args);
        if (actionInfo) {
            !record.hookBlock?:record.hookBlock(className,actionName,actionInfo,params.copy);
        }
        [invocation setTarget:self];
        [invocation setSelector:hookSelect];
        [invocation invoke];
        
        char *returnType = method_copyReturnType(originMethod);
        return getInvocationReturnValue(invocation,returnType);
        
    }
    return nil;
}
/**
 *  invocation调用完成后，在调用这个方法得到函数的返回值
 */
void * getInvocationReturnValue(NSInvocation *invocation,char *type){
    if (strcmp(type, @encode(void)) == 0) {
        return nil;
    }
    void *value;
    [invocation getReturnValue:&value];
    return value;
}
/**
 *  得到不定参数的值，并设置到invocation中，最后把值返回
 */
id setInvocationParam(NSInvocation *invocation,int index,va_list list,char *type){
    if (strcmp(type, @encode(id)) == 0) {
        id param = va_arg(list, id);
        [invocation setArgument:&param atIndex:index];
        return param;
    }
    if (strcmp(type, @encode(NSInteger)) == 0 ||
        strcmp(type, @encode(SInt8)) == 0  ||
        strcmp(type, @encode(SInt16)) == 0 ||
        strcmp(type, @encode(SInt32)) == 0 ||
        strcmp(type, @encode(BOOL)) == 0 ) {
        NSInteger param = va_arg(list, NSInteger);
        [invocation setArgument:&param atIndex:index];
        return @(param);
    }
    if (strcmp(type, @encode(NSUInteger)) == 0 ||
        strcmp(type, @encode(UInt8)) == 0  ||
        strcmp(type, @encode(UInt16)) == 0 ||
        strcmp(type, @encode(UInt32)) == 0 ) {
        NSUInteger param = va_arg(list, NSUInteger);
        [invocation setArgument:&param atIndex:index];
        return @(param);
    }
    
    if (strcmp(type, @encode(CGFloat)) == 0||
        strcmp(type, @encode(float)) == 0) {
        CGFloat param = va_arg(list, double);
        [invocation setArgument:&param atIndex:index];
        return @(param);
    }
    if (strcmp(type,@encode(void (^)())) == 0) {
        id param = va_arg(list, id);
        [invocation setArgument:&param atIndex:index];
        return param;
    }
    return nil;
}

/**
 *  在subClass的原型链上找最靠近该类的父类实现了这个实例方法,
 */
Class getClassThatImplementThisMethod(Class subClass,Method m){
    Class classImplenmentThisInstanceMethod = subClass;
    while (classImplenmentThisInstanceMethod) {
        unsigned int count  = 0;
        Method *methods =  class_copyMethodList(classImplenmentThisInstanceMethod, &count);
       
        //函数地址表有序排列，直接比较地址大小，不遍历
        if (count >0) {
            //因为hook的时候，给class加了一些以bnrHook或者hnrHookOrigin开头的函数
            //要除去这些函数，地址分布才是线性的
            unsigned int start = 0;
            while (start < count) {
                SEL mm = method_getName(methods[start]);
                NSString *mmName = NSStringFromSelector(mm);
                if ([mmName containsString:@"bnrHook"]||
                    [mmName containsString:@"bnrHookOrigin"]) {
                    start++;
                }else{
                    break;
                }
            }
            if (m >= methods[start]&&
                m <= methods[count-1]) {
                return classImplenmentThisInstanceMethod;
            }
        }

        classImplenmentThisInstanceMethod = class_getSuperclass(classImplenmentThisInstanceMethod);
    }
    return classImplenmentThisInstanceMethod;
}
/**
 *  在subClass的原型链上找具体是哪个父类(或者是就是这个类)实现了这个实例方法
 */
Class getClassThatImplenmentThisInstanceMethod(Class subClass, SEL selector){
    /*
     * 不能用此种方法，如ABCD是依次继承关系，BC都实现了该方法，我们需要交换的方法是C上的方法，
     * 而不是B上的，还是只能读出类的所有方法一个一个对比
     */
    Class classImplenmentThisInstanceMethod = subClass;
    while (classImplenmentThisInstanceMethod) {
        Class tmpClass = class_getSuperclass(classImplenmentThisInstanceMethod);
        if (class_getInstanceMethod(tmpClass, selector)) {
            classImplenmentThisInstanceMethod = tmpClass;
        }else{
            break;
        }
    }
    return classImplenmentThisInstanceMethod;
}
/**
 *  在subClass的原型链上找具体是哪个父类(或者是就是这个类)实现了这个类方法
 */
Class getClassThatImplementThisClassMethod(Class subClass, SEL selector){
    
    Class classImplenmentThisClassMethod = subClass;
    while (classImplenmentThisClassMethod) {
        Class tmpClass = class_getSuperclass(classImplenmentThisClassMethod);
        if (class_getClassMethod(tmpClass, selector)) {
            classImplenmentThisClassMethod = tmpClass;
        }else{
            break;
        }
    }
    return classImplenmentThisClassMethod;
}

/**
 *  所有需要hook并不需要调用源函数的函数都hook到了这个方法
 */
-(void)setRecordDic:(NSDictionary *)recordDic
    andWithOutCallOriginFuncHookBlock:(void *(^)(NSString *target,
                                                NSString *action,
                                                NSDictionary *handleDic,
                                                NSDictionary *params))handleBlock{
    
    _hookWithoutCallOriginDic = recordDic;
    self.hookBlockWithoutCallOriginFunc = handleBlock;
    
    dispatch_async(_serialQueue, ^{
        NSArray *allKeys = self.hookWithoutCallOriginDic.allKeys;
        for (NSString *className in allKeys) {
            NSDictionary *actionDic = self.hookWithoutCallOriginDic[className];
            Class classInstance = NSClassFromString(className);
            NSArray *actionKeys = actionDic.allKeys;
            for (NSString *actionName in actionKeys) {
                Method originMethod = class_getInstanceMethod(classInstance, NSSelectorFromString(actionName));
                if (originMethod) {
                    Class classImplenmentThisInstanceMethod = getClassThatImplementThisMethod(classInstance,originMethod);
                    
                    class_addMethod(classImplenmentThisInstanceMethod,
                                    NSSelectorFromString([NSString stringWithFormat:@"bnrHookOrigin_%@",actionName]),
                                    method_getImplementation(originMethod),
                                    method_getTypeEncoding(originMethod));
                    method_setImplementation(originMethod, (IMP)hookFuncWithOutCallOriginFunc);
                }else{
                    originMethod = class_getClassMethod(classInstance, NSSelectorFromString(actionName));
                    if (originMethod) {
                        Class metaClassImplementThisMethod = getClassThatImplementThisMethod(objc_getMetaClass(class_getName(classInstance)), originMethod);
                        
                        class_addMethod(metaClassImplementThisMethod,
                                        NSSelectorFromString([NSString stringWithFormat:@"bnrHookOrigin_%@",actionName]),
                                        method_getImplementation(originMethod),
                                        method_getTypeEncoding(originMethod));
                        method_setImplementation(originMethod, (IMP)hookFuncWithOutCallOriginFunc);
                    }
                    
                }
                
            }
            
        }
    });
}


void* hookFuncWithOutCallOriginFunc(id self, SEL _cmd,...){
    BNRHookAction *record = [BNRHookAction shareInstance];
    NSString *className = NSStringFromClass([self class]);
    NSDictionary *actionDic = record.hookWithoutCallOriginDic[className];
    NSString *actionName = NSStringFromSelector(_cmd);
    NSDictionary *actionInfo = actionDic[actionName];
        
    SEL hookSelect = NSSelectorFromString([NSString stringWithFormat:@"bnrHookOrigin_%@",NSStringFromSelector(_cmd)]);
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"self"] = self;
    params[@"_cmd"] = NSStringFromSelector(_cmd);
    
    
    NSMethodSignature *methodSig = [self methodSignatureForSelector:hookSelect];
    NSInvocation *invocation = nil;
    if (methodSig != nil) {
        invocation = [NSInvocation invocationWithMethodSignature:methodSig];
    }
   
    Method originMethod = class_getInstanceMethod([self class], _cmd);
    if (originMethod == nil) {
        originMethod = class_getClassMethod(self, _cmd);
    }
    unsigned int argsCount = method_getNumberOfArguments(originMethod);
    va_list args;
    va_start(args, _cmd);

    for (int i = 2; i < argsCount; i++) {
        char *paramType = method_copyArgumentType(originMethod, i);
        id param = setInvocationParam(invocation, i, args, paramType);
        params[[NSString stringWithFormat:@"%@",@(i-2)]] = param;
    }
    va_end(args);
    
    //当子类继承基类的方法时，即使字典中写的子类，基类的方法也会被hook,
    //所以这里判断当前调用是基类(基类的其他子类)还是子类，如果是子类，就调用block,不调用原函数
    //如果是基类就不调用block,并调用原函数
    
    if (actionInfo) {
        if (record.hookBlockWithoutCallOriginFunc) {
            void *value = record.hookBlockWithoutCallOriginFunc(className,actionName,actionInfo,params.copy);
            return value;
        }
        return nil;
    }else{
        if ([self respondsToSelector:hookSelect]){
            [invocation setTarget:self];
            [invocation setSelector:hookSelect];
            [invocation invoke];
            char *returnType = method_copyReturnType(originMethod);
            return getInvocationReturnValue(invocation,returnType);
        }
        return nil;
    }
    
}

@end
