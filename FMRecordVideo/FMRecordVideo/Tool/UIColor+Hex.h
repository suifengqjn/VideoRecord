//
//  UIColor+Hex.h
//  Parrot
//
//  Created by DengLiujun on 16/1/4.
//  Copyright © 2016年 liujun.me. All rights reserved.
//
//  Github:https://github.com/suifengqjn
//  blog:http://gcblog.github.io/
//  简书:http://www.jianshu.com/u/527ecf8c8753
#import <UIKit/UIKit.h>

@interface UIColor (Hex)

+ (UIColor*)colorWithRGB:(NSUInteger)hex alpha:(CGFloat)alpha;

+ (UIColor *)colorWithHexString:(NSString *)hexString;
+ (UIColor*)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

@end
