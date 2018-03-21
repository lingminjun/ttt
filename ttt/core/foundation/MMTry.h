//
//  MMTry.h
//  ttt
//
//  Created by MJ Ling on 2018/1/18.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MMTry : NSObject
/**
 * Provides try catch functionality for swift by wrapping around Objective-C
 * 仅仅可能包含oc异常抛出使用
 */
+ (void)try:(void (^)(void))try catch:(void (^)(NSException *))catch finally:(void (^)(void))finally;

//安全的反射出view controller
//+ (UIViewController *)safeViewController:(NSString *)vcName;

@end
