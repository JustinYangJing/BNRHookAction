## BNRHookAction

- 根据字典hook调用的方法，之前您传入的block,再执行原函数，可以实现无侵入式埋点； 
- 根据字典hook调用的方法，只会执行您传入的block,而不调用原函数


### 注意事项
>不支持为父类和子类同时hook同一个函数(如A是父类，A1和A2是子类，A1实现了`viewWillAppear:`,A2未实现，同时hook A的`viewWillAppear:`和A1的`viewWillAppear:`会造成死循环; 同时hook A1和A2的`viewWillAppear:`也会造成调用的死循环，其实A2未实现`viewWillAppear:`,hook A2时，就是hook的A的`viewWillAppear:`. 如果子类不调用[super method]是不会造成调用死循环。)

>hook函数时，请保证hook的target有实现hook的action,而不是父类实现了这个action.


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
 想要`hook` `className`下的`actionName`方法，`className`表示类名，`actionName`表示函数名，源码会根据这两个key值去hook。key1和value1，您可以自定义，比如做统计时,以eventId为key,在友盟或百度统计平台上自定义的事件Id为value,只要在传进来的block里面调用[MobClick event:value]就能做无侵入式埋点了，hook字典可以由后台下发。value也可以为block，调用您事先定义好的block
 
 

 
    
