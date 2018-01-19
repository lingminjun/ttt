//
//  MMTry.m
//  ttt
//
//  Created by MJ Ling on 2018/1/18.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

#import "MMTry.h"

@implementation MMTry
/**
 Provides try catch functionality for swift by wrapping around Objective-C
 */
+ (void)try:(void (^)(void))try catch:(void (^)(NSException *))catch finally:(void (^)(void))finally {
    @try {
        if (try != NULL) try();
    }
    @catch (NSException *exception) {
        if (catch != NULL) catch(exception);
    }
    @finally {
        if (finally != NULL) finally();
    }
}

@end
