## BNRHookAction
>`BNRHookAction`根据您传入的字典hook您在字典中定义的方法，当您调用这些方法时，会先调用您传入的block，再调用您的方法，借用这种技术，可以实现无侵入式埋点。


### 引入
	pod 'BNRHookAction'
	
### 使用
	 [[BNRHookAction shareInstance] 	
	 			setRecordDic:recordDic
                                   
               andHookBlock:^(NSString *target, NSString *action, NSDictionary *handleDic) {
                                           NSLog(@"hook %@",action);
                                                                  
                                   }];

### 参数说明
- recordDic
 		
 		{"ClassName1":{
                "actionName1":{
                    "key1":"value1";
                    "key2":"value2"};
                 "actionName2":{
                 "key1":"value1";
                 "key2":"value2"}
                };
     	"ClassName2":{
                 "actionName1":{
                 "key1":"value1";
                 "key2":"value2"};
                 "actionName2":{
                 "key1":"value1";
                 "key2":"value2"}
                 }
    			}
 想要`hook` `className`下的`actionName`方法，`className`表示类名，`actionName`表示函数名，源码会根据这两个key值去hook。key1和value1，您可以自定义，比如做统计时,以eventId为key,在友盟或百度统计平台上自定义的事件Id为value,只要在传进来的block里面调用[MobClick event:value]就能做无侵入式埋点了，hook字典可以由后台下发。value也可以为block，调用您事先定义好的block
 
 
    
