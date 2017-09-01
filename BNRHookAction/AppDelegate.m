//
//  AppDelegate.m
//  BNRHookAction
//
//  Created by JustinYang on 2017/8/26.
//  Copyright © 2017年 JustinYang. All rights reserved.
//

#import "AppDelegate.h"
#import <UMengAnalytics/UMMobClick/MobClick.h>
#import "BNRHookAction.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self umengConfig];
    return YES;
}
-(void)umengConfig{
    UMConfigInstance.appKey = @"xxxxxx";
    UMConfigInstance.channelId = @"App Store";
    [MobClick startWithConfigure:UMConfigInstance];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"record" ofType:@"plist"];
    NSDictionary *recordDic = [NSDictionary dictionaryWithContentsOfFile:path];
    [[BNRHookAction shareInstance] setRecordDic:recordDic
                                   andHookBlock:^(NSString *target, NSString *action, NSDictionary *handleDic) {
                                       NSString *eventId = handleDic[@"eventId"];
                                       if ([eventId isKindOfClass:[NSString class]]) {
                                           NSLog(@"hook %@",action);
                                           [MobClick event:eventId];
                                       }
                                   }];
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"hookWithoutCallOriginFunc" ofType:@"plist"];
    NSDictionary *recordDic1 = [NSDictionary dictionaryWithContentsOfFile:path1];
    [[BNRHookAction shareInstance] setRecordDic:recordDic1 andWithOutCallOriginFuncHookBlock:^void *(NSString *target, NSString *action, NSDictionary *handleDic, NSDictionary *params) {
        if ([target isEqualToString:@"TestVC"])
        {
            if ([action isEqualToString:@"hookBtnHandle:"]) {
                NSLog(@"hook hookBtnHandle:");
                return 0;
            }
            if ([action isEqualToString:@"testFuncWithIdParams:"]) {
                NSString *param = params[@"1"];
                int value = [param intValue];
                return value;
            }
        }
        return 0;
    }];

}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
