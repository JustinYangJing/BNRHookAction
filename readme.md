## BNRHookAction

- 根据字典`hook``OC`方法，先执行您传入的`block`,再执行原函数，可用于无侵入式埋点； 
- 根据字典`hook``OC`方法，只会执行您传入的`block`,而不调用原函数,可用于修改函数的执行


### 注意事项
>- 不支持`hook`参数为结构体的函数
>- 不支持父类子类`hook`同一个函数
>- `hook`某类的某个方法，该类必须实现这个方法
>- `arm64`结构上，`hook`的函数参数个有限制，最多8个非浮点类型参数和8个浮点类型参数
>- 使用时，`hook`不成功的函数会打印出来，并列出原因



### 引入
	pod 'BNRHookAction'
	
### 使用
该方法根据您传入的`recordDic `,先调用block,再调用原函数

	 [[BNRHookAction shareInstance] 	
	 			setRecordDic:recordDic
                                   
               andHookBlock:^(
               NSString *target, 
               NSString *action, 
               NSDictionary *handleDic,
               NSDictionary *params) {
                                           				NSLog(@"hook %@",action);
                                                                  
                                   }];
                                   
                                   
 该方法根据您传入的`recordDic`,只调用block，不会再调用原函数
 
 	[[BNRHookAction shareInstance] 	
 			setRecordDic:recordDic1 	
 			andWithOutCallOriginFuncHookBlock:
 			^void *(NSString *target, 
 			NSString *action, 
 			NSDictionary *handleDic, 
 			NSDictionary *params) {
	        if (...)
	        {
				//根据block的参数，执行特定的代码，
				//原函数可能会有返回值，您可以在这里修改
				//原函数的返回值
	        }
	        return nil;
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
想要`hook` `className`下的`actionName`方法，`className`表示类名，`actionName`表示函数名，源码会根据这两个key值去hook。key1和value1，您可以自定义，比如做统计时,以eventId为key,在友盟或百度统计平台上自定义的事件Id为value,只要在传进来的block里面调用[MobClick event:value]发送统计数据到友盟，hook字典可以由后台下发。value也可以为block，调用您事先定义好的block

### 链接
[`x86_64``arm32``arm64`传参分析](http://lifestyle1.cn/2018/06/14/iOS%E4%BA%A4%E6%8D%A2%E6%96%B9%E6%B3%95%E5%88%86%E6%9E%90/)
 
 

 
    
