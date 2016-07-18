//
//  DDRemoteAccess.m
//  Pods
//
//  Created by wangyang on 16/7/14.
//
//

#import "DDRemoteAccess.h"
#import "DDLogFilesResultBuilder.h"

#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>

@interface DDRemoteAccess() <GCDWebServerDelegate>
@property (assign,nonatomic) NSUInteger serverPort;
@property (strong,nonatomic) GCDWebServer* webserver;
@property (strong,nonatomic) DDRemoteAccessEnableCompleteBlock enableCompleteBlock;
@property (strong,nonatomic) DDFileLogger* fileLogger;
@end

@implementation DDRemoteAccess
+(void)configPort:(NSUInteger)port
{
    [DDRemoteAccess shared].serverPort = port;
}

+ (void)enableRemoteAccessWithCompleteBlock:(DDRemoteAccessEnableCompleteBlock)completeBlock
{
    [GCDWebServer setLogLevel:0];//no log
    [DDRemoteAccess shared].enableCompleteBlock = completeBlock;
    [[DDRemoteAccess shared].webserver startWithPort:[DDRemoteAccess shared].serverPort bonjourName:@"remote-log"];
}

+ (DDRemoteAccess*)shared
{
    static DDRemoteAccess* _shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [DDRemoteAccess new];
    });
    return _shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self configDDLog];
        self.serverPort = 15000;//default port
    }
    return self;
}

- (void)configDDLog
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
    self.fileLogger = [[DDFileLogger alloc] init]; // File Logger
    self.fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    self.fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:self.fileLogger];
}

- (NSString *)logDirPath
{
    NSString* dirPath = [self.fileLogger.logFileManager logsDirectory];
    return dirPath;
}

- (void)registerWebServerHandlers:(GCDWebServer*)webserver
{
    NSString* logsDir = [self logDirPath];
    [webserver addHandlerForMethod:@"GET" path:@"/logs" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
        NSString* baseUrl = webserver.serverURL;
        GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithText:[DDLogFilesResultBuilder buildJsonForFilesInDir:logsDir baseUrl:baseUrl]];
        return response;
    }];
    
    [webserver addHandlerForMethod:@"GET" path:@"/log" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
        NSString* baseUrl = webserver.serverURL;
        NSString* filename = [request query][@"file"];
        GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithText:[DDLogFilesResultBuilder fileContentWithName:filename inDir:logsDir]];
        return response;
    }];
    
    [webserver addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
        NSString* baseUrl = webserver.serverURL;
        GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithText:[DDLogFilesResultBuilder latestFileContentInDir:logsDir]];
        return response;
    }];
}

#pragma mark - GCDWebServer Delegate
- (void)webServerDidStart:(GCDWebServer*)server
{
    if(self.enableCompleteBlock != nil)
    {
        self.enableCompleteBlock(YES,[server.serverURL absoluteString]);
    }
}

- (void)webServerDidStop:(GCDWebServer *)server
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [server start];
    });
}

#pragma mark - Getter & Setter
-(GCDWebServer *)webserver
{
    if(_webserver == nil)
    {
        _webserver = [[GCDWebServer alloc]init];
        _webserver.delegate = self;
        [self registerWebServerHandlers:_webserver];
    }
    return _webserver;
}

@end
