//
//  BOCeClang.m
//  Industrial
//
//  Created by boce on 2020/11/9.
//  Copyright © 2020 boce. All rights reserved.
//

#import "BOCeClang.h"
#import <dlfcn.h>
#import <libkern/OSAtomic.h>

@implementation BOCeClang

void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,uint32_t *stop){
    static uint64_t N;//Counter for the guards.
    if (start == stop || *start)
        return;// Initialize only once.
    for (uint32_t *x = start; x < stop; x++){
        *x = ++N;// Guards should start from 1.
    }
}

typedef struct {
    void *pc;
    void *next;
}SymbolNode;

static  OSQueueHead symbolList = OS_ATOMIC_QUEUE_INIT; //定义符号结构体

void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
    if (!*guard){
       return;
    }
    void *PC = __builtin_return_address(0);
    SymbolNode *node = malloc(sizeof(SymbolNode));
    *node = (SymbolNode){PC,NULL};
    OSAtomicEnqueue(&symbolList,node,offsetof(SymbolNode, next));
}

+ (void)generateOrderFile{
    NSMutableArray <NSString *> *symbolNames = [NSMutableArray array];
    while (YES) {
        SymbolNode * node = OSAtomicDequeue(&symbolList, offsetof(SymbolNode, next));
        if (node == NULL) {
            break;
        }
        Dl_info info;
        dladdr(node->pc, &info);
        NSString *name = @(info.dli_sname);
        // 判断是不是oc方法，是的话直接加入符号数组
        BOOL isInstanceMethod = [name hasPrefix:@"-["];
        BOOL isClassMethod = [name hasPrefix:@"+["];
        BOOL isObjc = isInstanceMethod || isClassMethod;
        NSString * symbolName = isObjc ? name: [@"_" stringByAppendingString:name];
        [symbolNames addObject:symbolName];
    }
    // 取反:将先调用的函数放到前面
    NSEnumerator * emt = [symbolNames reverseObjectEnumerator];
    NSMutableArray<NSString *> *funcs = [NSMutableArray arrayWithCapacity:symbolNames.count];
    NSString *name;
    while (name = [emt nextObject]) {
        if (![funcs containsObject:name]) {
            [funcs addObject:name];
        }
    }
    // 由于trace了所有执行的函数，这里我们就把本函数移除掉
    [funcs removeObject:[NSString stringWithFormat:@"%s",__FUNCTION__]];
    // 写order文件
    NSString *funcStr = [funcs componentsJoinedByString:@"\n"];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"htclangtrace.order"];
    NSData *fileContents = [funcStr dataUsingEncoding:NSUTF8StringEncoding];
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileContents attributes:nil];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        NSLog(@"orderPath:%@",filePath);
    }else{
        NSLog(@"生成orderPath失败");
    }
}

#pragma mark - Util
+ (BOOL)isObjcMethodBySymbolName:(NSString *)symbolName{
    BOOL isInstanceMethod = [symbolName hasPrefix:@"-["];
    BOOL isClassMethod = [symbolName hasPrefix:@"+["];
    return isInstanceMethod || isClassMethod;
}

@end
