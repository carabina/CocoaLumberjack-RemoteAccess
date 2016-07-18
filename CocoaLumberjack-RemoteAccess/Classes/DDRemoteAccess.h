//
//  DDRemoteAccess.h
//  Pods
//
//  Created by wangyang on 16/7/14.
//
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

typedef void(^DDRemoteAccessEnableCompleteBlock)(BOOL isSuccess,NSString* visitUrl);

#define DRStrMerge(str1,str2) [str1 stringByAppendingString:str2]
//使用时请定义宏
//TEST : #define ddLogLevel DDLogLevelVerbose
//Product: #define ddLogLevel DDLogLevelInfo
//为不同Level的log加上输出前缀
#define DRLogError(fmt, ...) DDLogError(DRStrMerge(@"Error: ",fmt), ##__VA_ARGS__)
#define DRLogWarn(fmt, ...) DDLogWarn(DRStrMerge(@"Warn: ",fmt), ##__VA_ARGS__)
#define DRLogInfo(fmt, ...) DDLogInfo(DRStrMerge(@"Info: ",fmt), ##__VA_ARGS__)

#define DRLogDBG(fmt, ...) DDLogDebug(DRStrMerge(@"DBG: ",fmt), ##__VA_ARGS__)

@interface DDRemoteAccess : NSObject
+ (void)configPort:(NSUInteger)port;//default port is 15000
+ (void)enableRemoteAccessWithCompleteBlock:(DDRemoteAccessEnableCompleteBlock)completeBlock;
@end
