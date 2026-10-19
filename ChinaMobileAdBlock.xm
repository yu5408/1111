//
//  ChinaMobileAdBlock.xm
//  中国移动APP 开屏广告深度去除插件
//
//  多层拦截策略：
//  1. UI控制器层：Hook开屏广告VC，直接dismiss
//  2. 视图层：检测并移除广告视图
//  3. 网络层：拦截广告API请求，返回空数据
//  4. 特征识别：通过跳过按钮、倒计时等特征识别
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#pragma mark - 配置

// 中国移动广告API域名和路径
static NSString *const kAdAPIPath1 = @"/gfms/front/";
static NSString *const kAdAPIPath2 = @"getAdvert";
static NSString *const kAdDomain = @"10086.online-cmcc.cn";

// 广告控制器类名关键词（根据逆向经验整理）
static NSArray *kAdClassKeywords = @[
    @"SplashAD",
    @"SplashAd",
    @"LaunchAd",
    @"Advertise",
    @"ADLaunch",
    @"OpenScreen",
    @"WelcomeAd",
    @"MGSplash",       // 咪咕SDK
    @"ADContainer",
    @"SplashViewController",
    @"ADViewController",
    @"CMCCAd",
    @"MobileAd",
];

// 广告视图类名关键词
static NSArray *kAdViewKeywords = @[
    @"AdView",
    @"SplashAdView",
    @"AdvertiseView",
    @"LaunchAdImageView",
    @"AdContainerView",
];

#pragma mark - 工具类

@interface CMDAdBlockHelper : NSObject
+ (instancetype)shared;

- (BOOL)isAdViewController:(UIViewController *)vc;
- (void)dismissAdViewController:(UIViewController *)vc;
- (void)removeAdViewsFromWindow:(UIWindow *)window;
- (BOOL)isAdRequest:(NSURLRequest *)request;
- (UIWindow *)keyWindow;
@end

@implementation CMDAdBlockHelper

+ (instancetype)shared {
    static CMDAdBlockHelper *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

// 判断是否是广告控制器
- (BOOL)isAdViewController:(UIViewController *)vc {
    if (!vc) return NO;
    
    NSString *className = NSStringFromClass([vc class]);
    
    // 匹配类名关键词
    for (NSString *keyword in kAdClassKeywords) {
        if ([className containsString:keyword]) {
            return YES;
        }
    }
    
    // 检查是否包含跳过按钮（特征识别）
    if ([self hasSkipButtonInView:vc.view]) {
        return YES;
    }
    
    // 检查是否是全屏模态展示且有倒计时
    if (vc.modalPresentationStyle == UIModalPresentationFullScreen) {
        if ([self hasCountdownLabelInView:vc.view]) {
            return YES;
        }
    }
    
    return NO;
}

// 检查视图中是否有跳过按钮
- (BOOL)hasSkipButtonInView:(UIView *)view {
    if (!view) return NO;
    
    // 递归查找跳过按钮
    for (UIView *subview in view.subviews) {
        // 检查UIButton
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)subview;
            NSString *title = [btn titleForState:UIControlStateNormal];
            if ([title containsString:@"跳过"] || 
                [title containsString:@"Skip"] ||
                [title containsString:@"关闭"]) {
                return YES;
            }
        }
        
        // 检查UILabel
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            if ([label.text containsString:@"跳过"] ||
                [label.text containsString:@"倒计时"]) {
                return YES;
            }
        }
        
        // 递归子视图
        if ([self hasSkipButtonInView:subview]) {
            return YES;
        }
    }
    
    return NO;
}

// 检查是否有倒计时标签
- (BOOL)hasCountdownLabelInView:(UIView *)view {
    if (!view) return NO;
    
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            NSError *error = nil;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d+秒" options:0 error:&error];
            if ([regex firstMatchInString:label.text options:0 range:NSMakeRange(0, label.text.length)]) {
                return YES;
            }
        }
        
        if ([self hasCountdownLabelInView:subview]) {
            return YES;
        }
    }
    
    return NO;
}

// 关闭广告控制器
- (void)dismissAdViewController:(UIViewController *)vc {
    if (!vc) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[CMCCAdBlock] Dismissing ad VC: %@", NSStringFromClass([vc class]));
        
        // 方法1：如果是presented的，直接dismiss
        if (vc.presentingViewController) {
            [vc dismissViewControllerAnimated:NO completion:nil];
            return;
        }
        
        // 方法2：如果是rootViewController，找到真正的主界面
        UIWindow *window = [self keyWindow];
        if (window && window.rootViewController == vc) {
            // 直接从视图层级移除广告视图
            for (UIView *subview in window.subviews) {
                if ([self isAdView:subview]) {
                    [subview removeFromSuperview];
                    NSLog(@"[CMCCAdBlock] Removed ad view: %@", NSStringFromClass([subview class]));
                }
            }
        }
    });
}

// 判断是否是广告视图
- (BOOL)isAdView:(UIView *)view {
    if (!view) return NO;
    
    NSString *className = NSStringFromClass([view class]);
    
    for (NSString *keyword in kAdViewKeywords) {
        if ([className containsString:keyword]) {
            return YES;
        }
    }
    
    // 检查是否有跳过按钮
    if ([self hasSkipButtonInView:view]) {
        return YES;
    }
    
    return NO;
}

// 从window中移除广告视图
- (void)removeAdViewsFromWindow:(UIWindow *)window {
    if (!window) return;
    
    NSMutableArray *adViewsToRemove = [NSMutableArray array];
    
    for (UIView *subview in window.subviews) {
        if ([self isAdView:subview]) {
            [adViewsToRemove addObject:subview];
        }
    }
    
    for (UIView *adView in adViewsToRemove) {
        [adView removeFromSuperview];
        NSLog(@"[CMCCAdBlock] Removed ad view from window: %@", NSStringFromClass([adView class]));
    }
}

// 判断是否是广告请求
- (BOOL)isAdRequest:(NSURLRequest *)request {
    NSString *urlString = request.URL.absoluteString;
    
    if ([urlString containsString:kAdDomain]) {
        if ([urlString containsString:kAdAPIPath1] || [urlString containsString:kAdAPIPath2]) {
            return YES;
        }
    }
    
    // 匹配更多广告API路径
    NSArray *adPaths = @[
        @"/gfms/",
        @"getAdvert",
        @"splashAd",
        @"launchAd",
        @"/ad/",
        @"advertise",
        @"/adApi/",
        @"adConfig",
    ];
    
    for (NSString *path in adPaths) {
        if ([urlString containsString:path]) {
            return YES;
        }
    }
    
    return NO;
}

- (UIWindow *)keyWindow {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
            }
        }
    } else {
        window = [UIApplication sharedApplication].keyWindow;
    }
    return window;
}

@end

#pragma mark - Hook UIViewController

%hook UIViewController

- (void)viewDidLoad {
    %orig;
    
    CMDAdBlockHelper *helper = [CMDAdBlockHelper shared];
    if ([helper isAdViewController:self]) {
        NSLog(@"[CMCCAdBlock] Detected ad VC in viewDidLoad: %@", NSStringFromClass([self class]));
        
        // 延迟执行，等视图加载完成
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [helper dismissAdViewController:self];
        });
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    CMDAdBlockHelper *helper = [CMDAdBlockHelper shared];
    if ([helper isAdViewController:self]) {
        NSLog(@"[CMCCAdBlock] Detected ad VC in viewDidAppear: %@", NSStringFromClass([self class]));
        [helper dismissAdViewController:self];
    }
}

// Hook presentViewController:animated:completion:
// 拦截即将弹出的广告控制器
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    
    CMDAdBlockHelper *helper = [CMDAdBlockHelper shared];
    
    if ([helper isAdViewController:viewControllerToPresent]) {
        NSLog(@"[CMCCAdBlock] Blocked presenting ad VC: %@", NSStringFromClass([viewControllerToPresent class]));
        // 不调用原始方法，直接拦截
        return;
    }
    
    %orig;
}

%end

#pragma mark - Hook UIWindow

%hook UIWindow

// Hook makeKeyAndVisible，在显示时检查广告视图
- (void)makeKeyAndVisible {
    %orig;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CMDAdBlockHelper shared] removeAdViewsFromWindow:self];
    });
}

%end

#pragma mark - Hook NSURLSession（网络层拦截）

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    CMDAdBlockHelper *helper = [CMDAdBlockHelper shared];
    
    if ([helper isAdRequest:request]) {
        NSLog(@"[CMCCAdBlock] Blocked ad request: %@", request.URL.absoluteString);
        
        // 返回空数据，模拟广告加载失败
        NSData *emptyData = [@"{\"data\":[]}" dataUsingEncoding:NSUTF8StringEncoding];
        NSHTTPURLResponse *emptyResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (completionHandler) {
                completionHandler(emptyData, emptyResponse, nil);
            }
        });
        
        // 返回一个空的task
        return [self dataTaskWithURL:[NSURL URLWithString:@"about:blank"]];
    }
    
    return %orig;
}

%end

#pragma mark - Hook UIApplication（启动后检查）

%hook UIApplication

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    
    // 启动后多次检查，应对延迟加载的开屏广告
    NSArray *delays = @[@(0.3), @(0.8), @(1.5), @(2.5)];
    
    for (NSNumber *delay in delays) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIWindow *window = [[CMDAdBlockHelper shared] keyWindow];
            if (window) {
                [[CMDAdBlockHelper shared] removeAdViewsFromWindow:window];
            }
        });
    }
}

%end

#pragma mark - 初始化

%ctor {
    @autoreleasepool {
        NSLog(@"[CMCCAdBlock] China Mobile Ad Block plugin loaded!");
        NSLog(@"[CMCCAdBlock] Target: cn.10086.app");
    }
}
