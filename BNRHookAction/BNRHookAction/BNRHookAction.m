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

+(BNRHookAction *)shareInstance{
    static dispatch_once_t onceToken;
    static BNRHookAction *hook;
    dispatch_once(&onceToken, ^{
        hook = [[BNRHookAction alloc] init];

    });
    return hook;
}

#pragma mark - private method
-(void)setRecordDic:(NSDictionary *)recordDic andHookBlock:(void (^)(NSString *target,
                                                                       NSString *action,
                                                                       NSDictionary *handleDic))handleBlock{
   
    _recordDic = recordDic;
    self.hookBlock = handleBlock;
    NSArray *allKeys = self.recordDic.allKeys;
    for (NSString *className in allKeys) {
        NSDictionary *actionDic = self.recordDic[className];
        Class classInstance = NSClassFromString(className);
        NSArray *actionKeys = actionDic.allKeys;
        for (NSString *actionName in actionKeys) {
            Method originMethod = class_getInstanceMethod(classInstance, NSSelectorFromString(actionName));
            if (originMethod) {
             class_addMethod(classInstance,
                                NSSelectorFromString([NSString stringWithFormat:@"hook_%@",actionName]),
                                method_getImplementation(originMethod),
                                method_getTypeEncoding(originMethod));
                method_setImplementation(originMethod, (IMP)hookFunc);
            }else{
                originMethod = class_getClassMethod(classInstance, NSSelectorFromString(actionName));
                if (originMethod) {
//                    const char *classChar = className.UTF8String;
                    class_addMethod(objc_getMetaClass(className.UTF8String),
                                    NSSelectorFromString([NSString stringWithFormat:@"hook_%@",actionName]),
                                    method_getImplementation(originMethod),
                                    method_getTypeEncoding(originMethod));
                    method_setImplementation(originMethod, (IMP)hookFunc);
                }
            
            }
            
        }
        
    }
}


void* hookFunc(id self, SEL _cmd,...){
    BNRHookAction *record = [BNRHookAction shareInstance];
    NSString *className = NSStringFromClass([self class]);
    NSDictionary *actionDic = record.recordDic[className];
    NSString *actionName = NSStringFromSelector(_cmd);
    NSDictionary *actionInfo = actionDic[actionName];
    !record.hookBlock?:record.hookBlock(className,actionName,actionInfo);
   
    SEL hookSelect = NSSelectorFromString([NSString stringWithFormat:@"hook_%@",NSStringFromSelector(_cmd)]);
    
    if ([self respondsToSelector:hookSelect]) {
        
        NSMethodSignature *methodSig = [self methodSignatureForSelector:hookSelect];
        if (methodSig == nil) {
            return 0;
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
            setInvocationParam(invocation, i, args, paramType);
        }
        va_end(args);
        [invocation setTarget:self];
        [invocation setSelector:hookSelect];
        [invocation invoke];
        
        char *returnType = method_copyReturnType(originMethod);
        return getInvocationReturnValue(invocation,returnType);
        
    }
    return 0;
}
void * getInvocationReturnValue(NSInvocation *invocation,char *type){
    if (strcmp(type, @encode(void)) == 0) {
        return 0;
    }
    void *value;
    [invocation getReturnValue:&value];
    return value;
}
void setInvocationParam(NSInvocation *invocation,int index,va_list list,char *type){
    if (strcmp(type, @encode(id)) == 0) {
        id param = va_arg(list, id);
        [invocation setArgument:&param atIndex:index];
        return;
    }
    if (strcmp(type, @encode(NSInteger)) == 0 ||
        strcmp(type, @encode(SInt8)) == 0  ||
        strcmp(type, @encode(SInt16)) == 0 ||
        strcmp(type, @encode(SInt32)) == 0 ||
        strcmp(type, @encode(BOOL)) == 0 ) {
        NSInteger param = va_arg(list, NSInteger);
        [invocation setArgument:&param atIndex:index];
        return;
    }
    if (strcmp(type, @encode(NSUInteger)) == 0 ||
        strcmp(type, @encode(UInt8)) == 0  ||
        strcmp(type, @encode(UInt16)) == 0 ||
        strcmp(type, @encode(UInt32)) == 0 ) {
        NSUInteger param = va_arg(list, NSUInteger);
        [invocation setArgument:&param atIndex:index];
        return;
    }
    
    if (strcmp(type, @encode(CGFloat)) == 0||
        strcmp(type, @encode(float)) == 0) {
        CGFloat param = va_arg(list, CGFloat);
        [invocation setArgument:&param atIndex:index];
        return;
    }
    if (strcmp(type,@encode(void (^)())) == 0) {
        id param = va_arg(list, id);
        [invocation setArgument:&param atIndex:index];
        return;
    }
}

@end
