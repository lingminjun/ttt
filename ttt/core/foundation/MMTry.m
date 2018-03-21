//
//  MMTry.m
//  ttt
//
//  Created by MJ Ling on 2018/1/18.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

#import "MMTry.h"
//#if TARGET_IPHONE_SIMULATOR
//#import <objc/objc-runtime.h>
//#else
#import <objc/runtime.h>
#import <objc/message.h>
//#endif

/*
@protocol UIViewControllerSafeInit
 - (instancetype)initTheNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil;
@end
*/
@implementation MMTry
/**
 Provides try catch functionality for swift by wrapping around Objective-C
 */
+ (void)try:(void (^)(void))try catch:(void (^)(NSException *))catch finally:(void (^)(void))finally {
    @try {
        if (try != NULL) try();
    } @catch (NSException *exception) {
        if (catch != NULL) catch(exception);
    } @finally {
        if (finally != NULL) finally();
    }
}

+ (NSString *)SWIFT_MODULE_NAME {
    static NSString *_SWIFT_MODULE_NAME = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *nameSpace = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleExecutable"];
        //命名空间，连字符“-”会被转换成下划线“_”
        nameSpace = [nameSpace stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
        
        _SWIFT_MODULE_NAME = nameSpace;
    });
    
    return _SWIFT_MODULE_NAME;
}

/*
+ (UIViewController *)safeViewController:(NSString *)vcName {
    NSString *nameSpace = [self SWIFT_MODULE_NAME];
    
    Class clazz = nil;
    if ([vcName rangeOfString:@"."].length <= 0) {
        @try {
            clazz = NSClassFromString([NSString stringWithFormat:@"%@.%@",nameSpace,vcName]);
        }  @catch (NSException *exception) {}
    }
    
    if (clazz == nil) {
        @try {
            clazz = NSClassFromString(vcName);
        }  @catch (NSException *exception) {}
    }
    
    @try {
//        Method methd1 = class_getInstanceMethod(UIViewController.class, @selector(initWithNibName:bundle:));
//        Method methd = class_getInstanceMethod(clazz, @selector(initWithNibName:bundle:));
//        IMP imp = method_getImplementation(methd);
//        NSLog(@"%@>>>>>%p===%p",vcName,imp,method_getImplementation(methd1));
//        NSArray *methods = [self getAllMethods:clazz];
        //无法判断控制器最后是否实现了 initWithNibName:bundle: 方法，只能统一采用新增方法初始化。
//        if ([methods containsObject:@"initWithNibName:bundle:"]) {
//            return [[clazz alloc] init];
//        } else {
//            return [[clazz alloc] initWithNibName:nil bundle:nil];
            return [[clazz alloc] initTheNibName:nil bundle:nil];//发现仍然存在问题，进入SCollectionViewController时出现了卡死，不知道什么情况
//        }
    }  @catch (NSException *exception) {NSLog(@"%@",exception);}
    
    return nil;
}
 */

/* 获取对象的所有方法 *//*
+(NSArray *)getAllMethods:(Class)clazz {
    unsigned int methodCount =0;
    Method* methodList = class_copyMethodList(clazz,&methodCount);
    NSMutableArray *methodsArray = [NSMutableArray arrayWithCapacity:methodCount];
    
    for (int i=0;i<methodCount;i++) {
        Method temp = methodList[i];
        IMP imp = method_getImplementation(temp);
        SEL name_f = method_getName(temp);
        const char* name_s =sel_getName(method_getName(temp));
        int arguments = method_getNumberOfArguments(temp);
        const char* encoding =method_getTypeEncoding(temp);
        NSLog(@"方法名：%@,参数个数：%d,编码方式：%@",[NSString stringWithUTF8String:name_s],
              arguments,
              [NSString stringWithUTF8String:encoding]);
        [methodsArray addObject:[NSString stringWithUTF8String:name_s]];
    }
    free(methodList);
    return methodsArray;
}
*/
@end

/*
@implementation UIViewController(SafeInit)

+ (void)initialize {
    Method method = class_getInstanceMethod(UIViewController.class, @selector(initWithNibName:bundle:));
    const char *method_type = method_getTypeEncoding(method);
    class_addMethod(UIViewController.class, @selector(initTheNibName:bundle:), method_getImplementation(method), method_type);
}

@end

@implementation UITableViewController(SafeInit)

+ (void)initialize {
    Method method = class_getInstanceMethod(UITableViewController.class, @selector(initWithNibName:bundle:));
    const char *method_type = method_getTypeEncoding(method);
    class_addMethod(UITableViewController.class, @selector(initTheNibName:bundle:), method_getImplementation(method), method_type);
}

@end

@implementation UINavigationController(SafeInit)

+ (void)initialize {
    Method method = class_getInstanceMethod(UINavigationController.class, @selector(initWithNibName:bundle:));
    const char *method_type = method_getTypeEncoding(method);
    class_addMethod(UINavigationController.class, @selector(initTheNibName:bundle:), method_getImplementation(method), method_type);
}

@end

@implementation UITabBarController(SafeInit)

+ (void)initialize {
    Method method = class_getInstanceMethod(UITabBarController.class, @selector(initWithNibName:bundle:));
    const char *method_type = method_getTypeEncoding(method);
    class_addMethod(UITabBarController.class, @selector(initTheNibName:bundle:), method_getImplementation(method), method_type);
}

@end

@implementation UISearchController(SafeInit)

+ (void)initialize {
    Method method = class_getInstanceMethod(UISearchController.class, @selector(initWithNibName:bundle:));
    const char *method_type = method_getTypeEncoding(method);
    class_addMethod(UISearchController.class, @selector(initTheNibName:bundle:), method_getImplementation(method), method_type);
}

@end
 */

