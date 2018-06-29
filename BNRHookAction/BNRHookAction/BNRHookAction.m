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

typedef NS_ENUM(NSInteger, HookType) {
    HookTypeNecessaryCallOrigin = 0 , //需要调用原函数
    HookTypeUnnecessaryCallOrigin = 1, //不需要调用原函数
};

typedef NS_ENUM(NSInteger,SupportType) {
    SupportTypeNoParamCount, //不支持hook超出参数个数的函数
    SupportTypeNoStruct, //不支持hook参数为结构体的函数
    SupportTypeNoClassHasNoThisMethod, //这个类没实现这个方法
    SupportTypeNoFatherAndChildHookSameMethod, //不能hook父类和子类相同的方法
    SupportTypeParamValid, //要hook的函数参数合法
    SupportTypeInstance,  //支持hook，并且该方法是实例方法
    SupportTypeClass,     //支持hook,并且该方式类方法
};

@interface BNRHookAction ()


/**
 *  hook的block,hook后的函数，会先调用这个block,再调用原函数
 */
@property (nonatomic,copy) void (^hookBlock)(NSString *target,NSString *action,NSDictionary *handleDic,NSDictionary *params);

/**
 *  有些情况不需要调用原来的函数，只要调用hook的这个block,原函数的参数会通过params传出来
 *  原函数可能要求返回值，那么请在您提供的block里面为原函数提供返回值
 */
@property (nonatomic,copy) void *(^hookBlockWithoutCallOriginFunc)(NSString *target,NSString *action,NSDictionary *handleDic,NSDictionary *params);
@end
@implementation BNRHookAction
{
    dispatch_queue_t _serialQueue;
    /**不支持hook函数原因的字典*/
    NSDictionary    *_supportErrDic;
    /**存取已经hook掉的方法名，避免父类和子类hook同一个方法*/
    NSMutableDictionary    *_alreadyHookActionDic;
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
        _supportErrDic = @{
                           @(SupportTypeNoParamCount):@"arm64位机器下,hook的函数参数个数超出了限制",
                           @(SupportTypeNoClassHasNoThisMethod):@"要hook的方法必须该类已经实现了它",
                           @(SupportTypeNoStruct):@"不支持hook参数为结构体类型的方法",
                           @(SupportTypeNoFatherAndChildHookSameMethod):@"不能hook子类和父类相同的方法"
                           };
        _alreadyHookActionDic = [NSMutableDictionary dictionary];
    }
    return self;
}

-(SupportType)couldHookThisMethod:(Class)cls :(SEL)sel{
    BOOL (^ImplentThisMethod)(Class,Method) = ^(Class cls,Method m){
        unsigned int count = 0;
        Method *methods = class_copyMethodList(cls, &count);
        for (int i = 0; i < count; i++) {
            Method tmpM = methods[i];
            if (tmpM == m) {
                return YES;
            }
        }
        return NO;
    };
#if defined(__arm64__)
    SupportType (^checkParam)(Class, Method) = ^(Class cls, Method m){
        unsigned int count = method_getNumberOfArguments(m);
        if (count > 16) {
            return SupportTypeNoParamCount;
        }
 
        for (int i = 2,fParamCount = 0, lParamCount = 2; i < count; i++) {
            char *paramType = method_copyArgumentType(m, i);
            NSString *typeStr = [NSString stringWithUTF8String:paramType];
            NSPredicate *predict = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"^\\{.*?=.*?\\}$"];
            if ([predict evaluateWithObject:typeStr]) {
                return SupportTypeNoStruct;
            }
            if (strcmp(paramType, @encode(float)) == 0 ||
                strcmp(paramType, @encode(double)) == 0) {
                fParamCount++;
            }else{
                lParamCount++;
            }
            
            if (fParamCount > 8 || lParamCount > 8) {
                return SupportTypeNoParamCount;
            }
        }

        return SupportTypeParamValid;
    };
#else
    SupportType (^checkParam)(Class, Method) = ^(Class cls, Method m){
        unsigned int count = method_getNumberOfArguments(m);
        for (int i = 2; i < count; i++) {
            char *paramType = method_copyArgumentType(m, i);

            NSString *typeStr = [NSString stringWithUTF8String:paramType];
            NSPredicate *predict = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"^\\{.*?=.*?\\}$"];
        
            if ([predict evaluateWithObject:typeStr]) {
                return SupportTypeNoStruct;
            }
        }
        
        return SupportTypeParamValid;
    };
#endif
    //是否父类子类hook了同一个方法
    NSString *className = _alreadyHookActionDic[NSStringFromSelector(sel)];
    if (className) {
        Class fatherClass = cls;
        while (fatherClass) {
            Class tmpClass = class_getSuperclass(fatherClass);
            if ([NSStringFromClass(tmpClass) isEqualToString:className]) {
                return SupportTypeNoFatherAndChildHookSameMethod;
            }else{
                fatherClass = tmpClass;
            }
        }
        
        fatherClass = NSClassFromString(className);
        while (fatherClass) {
            Class tmpClass = class_getSuperclass(fatherClass);
            if ([NSStringFromClass(tmpClass) isEqualToString:NSStringFromClass(cls)]) {
                return SupportTypeNoFatherAndChildHookSameMethod;
            }else{
                fatherClass = tmpClass;
            }
        }
    }
    
    Method m = class_getInstanceMethod(cls, sel);
    if (m) {
        if (NO == ImplentThisMethod(cls,m)){
            return SupportTypeNoClassHasNoThisMethod;
        }

        SupportType type = checkParam(cls,m);
        if (type == SupportTypeParamValid ) {
            return SupportTypeInstance;
        }
        return type;
    }else{
        m = class_getClassMethod(cls, sel);
        if (m == nil) {
            return SupportTypeNoClassHasNoThisMethod;
        }
        if (NO == ImplentThisMethod( objc_getMetaClass(class_getName(cls)),m)){
            return SupportTypeNoClassHasNoThisMethod;
        }
        SupportType type = checkParam(cls,m);
        if (type == SupportTypeParamValid ) {
            return SupportTypeClass;
        }
        return type;

    }
}

/**
 *  hook recordDic中记录的方法
 */
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
                
                SupportType type = [self couldHookThisMethod:classInstance :NSSelectorFromString(actionName)];
                if (_supportErrDic[@(type)]) {
                    NSLog(@"🚗%@的%@方法hook不成功🚗",className,actionName);
                    NSLog(@"%@",_supportErrDic[@(type)]);
                    continue;
                }
                
                
                Method originMethod;
                Class cls;
                if (type == SupportTypeClass) {
                    cls = objc_getMetaClass(class_getName(classInstance));
                    originMethod = class_getClassMethod(cls, NSSelectorFromString(actionName));
                }else{
                    cls = classInstance;
                    originMethod = class_getInstanceMethod(classInstance, NSSelectorFromString(actionName));
                }
                class_addMethod(cls,
                                NSSelectorFromString([NSString stringWithFormat:@"bnrHook_%@",actionName]),
                                method_getImplementation(originMethod),
                                method_getTypeEncoding(originMethod));
                method_setImplementation(originMethod, (IMP)hookFunc);
                
                _alreadyHookActionDic[actionName] = className;
                }
                
            }
    });
}

#if defined(__arm64__)
void* hookFunc(id self, SEL _cmd, ...){
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

    Method originMethod = class_getInstanceMethod([self class], _cmd);
    if (originMethod == nil) {
        originMethod = class_getClassMethod(self, _cmd);
    }
    unsigned int argsCount = method_getNumberOfArguments(originMethod);
    unsigned int pointParams = 0;
    for (int i = 2; i < argsCount; i++) {
        char *paramType = method_copyArgumentType(originMethod, i);
        if (strcmp(paramType, @encode(float)) == 0 ||
            strcmp(paramType, @encode(double)) == 0) {
            pointParams++;
        }
    }
    
    BNRHookAction *record = [BNRHookAction shareInstance];
    NSString *className = NSStringFromClass([self class]);
    NSDictionary *actionDic = record.recordDic[className];
    NSString *actionName = NSStringFromSelector(_cmd);
    NSDictionary *actionInfo = actionDic[actionName];
    
    SEL hookSelect = NSSelectorFromString([NSString stringWithFormat:@"bnrHook_%@",NSStringFromSelector(_cmd)]);
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"self"] = self;
    params[@"_cmd"] = NSStringFromSelector(_cmd);
    
#define kVar(type,num)  num==0?type##0:(num==1?type##1:(num==2?type##2:(num==3?type##3:(num==4?type##4:(num==5?type##5:(num==6?type##6:(num==7?type##7:0)))))))
    
    if ([self respondsToSelector:hookSelect]) {
        NSMethodSignature *methodSig = [self methodSignatureForSelector:hookSelect];
        if (methodSig == nil) {
            return (void *)0;
        }
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        
    //最多只能从寄存器中去16个值
    int maxRegCount = (pointParams + 8)>16?16:(pointParams + 8);
    for (int i = 2, pointCount = 0,longCount = 2; i < argsCount; i++) {
        char *paramType = method_copyArgumentType(originMethod, i);
        if (i <= maxRegCount) { //从寄存器中取值
            if (strcmp(paramType, @encode(float)) == 0) {
                if (pointCount < 8) {
                    float value = kVar(f, pointCount);
                    pointCount++;
                    [invocation setArgument:&value atIndex:i];
                    params[[NSString stringWithFormat:@"%@",@(i-2)]] = @(value);
                }
                
            }else if(strcmp(paramType, @encode(double)) == 0){
                if (pointCount < 8) {
                    double value = kVar(d, pointCount);
                    pointCount++;
                    [invocation setArgument:&value atIndex:i];
                    params[[NSString stringWithFormat:@"%@",@(i-2)]] = @(value);
                }
                
            }else{
                long value;
                if (longCount < 8) {
                    value = kVar(x, longCount);
                    longCount++;
                    if ([[NSString stringWithUTF8String:paramType] containsString:@"@"]) {
                        if (value == 0) {
                           params[[NSString stringWithFormat:@"%@",@(i-2)]] = [NSNull null];
                        }else{
                            void *p = (void *)value;
                            id temp = (__bridge id _Nullable)(p);
                            params[[NSString stringWithFormat:@"%@",@(i-2)]] = temp;
                            [invocation setArgument:&temp atIndex:i];
                        }
                    }else{
                        params[[NSString stringWithFormat:@"%@",@(i-2)]] = @(value);
                        [invocation setArgument:&value atIndex:i];
                    }
                }
            }
        }
    }
        if (actionInfo) {
            !record.hookBlock?:record.hookBlock(className,actionName,actionInfo,params.copy);
        }
        [invocation setTarget:self];
        [invocation setSelector:hookSelect];
        [invocation invoke];
        
        char *returnType = method_copyReturnType(originMethod);
        void *value = getInvocationReturnValue(invocation,returnType);
        free(returnType);
        return value;
    }
    return (void *)0;
}
#else
void* hookFunc(id self, SEL _cmd, ...){
    BNRHookAction *record = [BNRHookAction shareInstance];
    NSString *className = NSStringFromClass([self class]);
    NSDictionary *actionDic = record.recordDic[className];
    NSString *actionName = NSStringFromSelector(_cmd);
    NSDictionary *actionInfo = actionDic[actionName];

    
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
            id param = setInvocationParam(invocation, i, &args, paramType);
            if (param == nil) {
                params[[NSString stringWithFormat:@"%@",@(i-2)]] = [NSNull null];
            }else{
                params[[NSString stringWithFormat:@"%@",@(i-2)]] = param;
            }
            
        }
        va_end(args);
        if (actionInfo) {
            !record.hookBlock?:record.hookBlock(className,actionName,actionInfo,params.copy);
        }
        [invocation setTarget:self];
        [invocation setSelector:hookSelect];
        [invocation invoke];
        
        char *returnType = method_copyReturnType(originMethod);
        void *value = getInvocationReturnValue(invocation,returnType);
        free(returnType);
        return value;
        
    }
    return (void *)0;
}
#endif

/**
 *  得到不定参数的值，并设置到invocation中，最后把值返回
 */
id setInvocationParam(NSInvocation *invocation,int index,va_list *list,char *type){
    if (strcmp(type, @encode(NSInteger)) == 0 ||
        strcmp(type, @encode(SInt8)) == 0  ||
        strcmp(type, @encode(SInt16)) == 0 ||
        strcmp(type, @encode(SInt32)) == 0 ||
        strcmp(type, @encode(BOOL)) == 0) {
        NSInteger param = va_arg(*list, NSInteger);
        [invocation setArgument:&param atIndex:index];
        return @(param);
    }
    if (strcmp(type, @encode(NSUInteger)) == 0 ||
        strcmp(type, @encode(UInt8)) == 0  ||
        strcmp(type, @encode(UInt16)) == 0 ||
        strcmp(type, @encode(UInt32)) == 0 ) {
        NSUInteger param = va_arg(*list, NSUInteger);
        [invocation setArgument:&param atIndex:index];
        return @(param);
    }
    
    if (strcmp(type, @encode(float)) == 0) {
        float param = va_arg(*list, float);
        [invocation setArgument:&param atIndex:index];
        return @(param);
    }
    if (strcmp(type, @encode(double)) == 0) {
        double param = va_arg(*list, double);
        [invocation setArgument:&param atIndex:index];
        return @(param);
    }
    if ([[NSString stringWithUTF8String:type] containsString:@"@"]) {
        id param = va_arg(*list, id);
        [invocation setArgument:&param atIndex:index];
        return param;
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
                
                SupportType type = [self couldHookThisMethod:classInstance :NSSelectorFromString(actionName)];
                if (_supportErrDic[@(type)]) {
                    NSLog(@"🚗%@的%@方法hook不成功🚗",className,actionName);
                    NSLog(@"%@",_supportErrDic[@(type)]);
                    continue;
                }
                
                Method originMethod;
                Class cls;
                
                if (type == SupportTypeClass) {
                    cls = objc_getMetaClass(class_getName(classInstance));
                    originMethod = class_getClassMethod(cls, NSSelectorFromString(actionName));
                }else{
                    cls = classInstance;
                    originMethod = class_getInstanceMethod(classInstance, NSSelectorFromString(actionName));
                }
                
                class_addMethod(cls,
                                NSSelectorFromString([NSString stringWithFormat:@"bnrHookOrigin_%@",actionName]),
                                method_getImplementation(originMethod),
                                method_getTypeEncoding(originMethod));
                method_setImplementation(originMethod, (IMP)hookFuncWithOutCallOriginFunc);
            }
            
        }
    });
}

#if defined(__arm64__)
void* hookFuncWithOutCallOriginFunc(id self, SEL _cmd, ...){
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
    
    Method originMethod = class_getInstanceMethod([self class], _cmd);
    if (originMethod == nil) {
        originMethod = class_getClassMethod(self, _cmd);
    }
    unsigned int argsCount = method_getNumberOfArguments(originMethod);
    unsigned int pointParams = 0;
    for (int i = 2; i < argsCount; i++) {
        char *paramType = method_copyArgumentType(originMethod, i);
        if (strcmp(paramType, @encode(float)) == 0 ||
            strcmp(paramType, @encode(double)) == 0) {
            pointParams++;
        }
    }
    
    BNRHookAction *record = [BNRHookAction shareInstance];
    NSString *className = NSStringFromClass([self class]);
    NSDictionary *actionDic = record.hookWithoutCallOriginDic[className];
    NSString *actionName = NSStringFromSelector(_cmd);
    NSDictionary *actionInfo = actionDic[actionName];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"self"] = self;
    params[@"_cmd"] = NSStringFromSelector(_cmd);
    
#define kVar(type,num)  num==0?type##0:(num==1?type##1:(num==2?type##2:(num==3?type##3:(num==4?type##4:(num==5?type##5:(num==6?type##6:(num==7?type##7:0)))))))
    
    //最多只能从寄存器中去16个值
    int maxRegCount = (pointParams + 8)>16?16:(pointParams + 8);
    for (int i = 2, pointCount = 0,longCount = 2; i < argsCount; i++) {
        char *paramType = method_copyArgumentType(originMethod, i);
        if (i <= maxRegCount) { //从寄存器中取值
            if (strcmp(paramType, @encode(float)) == 0) {
                if (pointCount < 8) {
                    float value = kVar(f, pointCount);
                    pointCount++;
                
                    params[[NSString stringWithFormat:@"%@",@(i-2)]] = @(value);
                }
                
            }else if(strcmp(paramType, @encode(double)) == 0){
                if (pointCount < 8) {
                    double value = kVar(d, pointCount);
                    pointCount++;
                    
                    params[[NSString stringWithFormat:@"%@",@(i-2)]] = @(value);
                }
                
            }else{
                long value;
                if (longCount < 8) {
                    value = kVar(x, longCount);
                    longCount++;
                    if ([[NSString stringWithUTF8String:paramType] containsString:@"@"]) {
                        if (value == 0) {
                            params[[NSString stringWithFormat:@"%@",@(i-2)]] = [NSNull null];
                        }else{
                            void *p = (void *)value;
                            params[[NSString stringWithFormat:@"%@",@(i-2)]] = (__bridge id _Nullable)(p);
                        }
                    }else{
                        params[[NSString stringWithFormat:@"%@",@(i-2)]] = @(value);
                    }
                }
            }
        }
    }
    if (actionInfo && record.hookBlockWithoutCallOriginFunc) {
        return record.hookBlockWithoutCallOriginFunc(className,actionName,actionInfo,params.copy);
    }
    return (void *)0;
}
#else
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
        id param = setInvocationParam(invocation, i, &args, paramType);
        params[[NSString stringWithFormat:@"%@",@(i-2)]] = param;
    }
    va_end(args);


    if (actionInfo) {
        if (record.hookBlockWithoutCallOriginFunc) {
            void *value = record.hookBlockWithoutCallOriginFunc(className,actionName,actionInfo,params.copy);
            return value;
        }
        return nil;
    }
//    else{
//        if ([self respondsToSelector:hookSelect]){
//            [invocation setTarget:self];
//            [invocation setSelector:hookSelect];
//            [invocation invoke];
//            char *returnType = method_copyReturnType(originMethod);
//            return getInvocationReturnValue(invocation,returnType);
//        }
//        return nil;
//    }
    return (void *)0;
}
#endif
@end
