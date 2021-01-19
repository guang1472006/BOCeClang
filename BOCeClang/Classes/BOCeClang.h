//
//  BOCeClang.h
//  Industrial
//
//  Created by boce on 2020/11/9.
//  Copyright © 2020 boce. All rights reserved.
//

/*
 LLVM 具有内置的简单代码覆盖率检测工具（SanitizerCoverage）
 此文件的目的是为了生成orderfile文件、进行二进制重排优化启动速度。
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 在Other Swift Flags增加`-sanitize-coverage=func`,`-sanitize=undefined
 */
@interface BOCeClang : NSObject

/// 生成trace.order文件；一般我们要检测启动前执行的函数，所以放到首页的viewDidAppear中调用该函数
+(void)generateOrderFile;

@end

NS_ASSUME_NONNULL_END
