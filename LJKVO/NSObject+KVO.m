//
//  NSObject+KVO.m
//  LJKVO
//
//  Created by 李佳 on 2020/5/8.
//  Copyright © 2020 李佳. All rights reserved.
//

#import "NSObject+KVO.h"
#import <objc/message.h>
#import "LJKVOInfo.h"

static NSString *const kLJKVOPrefix = @"LJKVONotifying_";
static NSString *const kLJKVOAssiociateKey = @"kLJKVO_AssiociateKey";

@implementation NSObject (KVO)

- (void)lj_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(LJKeyValueObservingOptions)options context:(nullable void *)context{
    // 1: 验证是否存在setter方法
    [self judgeSetterMethodFromKeyPath:keyPath];
    // 2: 动态生成子类、实现方法
    Class newClass = [self createChildClassWithKeyPath:keyPath];
    // 3: isa 转向
    object_setClass(self, newClass);
    // 4: 保存当前观察者
    LJKVOInfo *info = [[LJKVOInfo alloc] initWitObserver:observer forKeyPath:keyPath options:options];
    NSMutableArray *observerArr = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kLJKVOAssiociateKey));
    
    if (!observerArr) {
        observerArr = [NSMutableArray arrayWithCapacity:1];
        [observerArr addObject:info];
        objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kLJKVOAssiociateKey), observerArr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}


- (void)lj_observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context{
    NSLog(@"change      %@", change);
}

- (void)lj_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    NSMutableArray *observerArr = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kLJKVOAssiociateKey));
    if (observerArr.count<=0) {
        return;
    }
    for (LJKVOInfo *info in observerArr) {
        if ([info.keyPath isEqualToString:keyPath]) {
            [observerArr removeObject:info];
            objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kLJKVOAssiociateKey), observerArr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            break;
        }
    }
    
    if (observerArr.count<=0) {
        // 指回给父类
        Class superClass = [self class];
        object_setClass(self, superClass);
    }
    
}

- (void)judgeSetterMethodFromKeyPath:(NSString *)keyPath{
    /*Step 1*/
    Class superClass    = object_getClass(self);
    /*Step 2*/
    SEL setterSeletor   = NSSelectorFromString(setterForGetter(keyPath));
    /*Step 3*/
    Method setterMethod = class_getInstanceMethod(superClass, setterSeletor);
    /*Step 4*/
    if (!setterMethod) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"没有当前%@的setter",keyPath] userInfo:nil];
    }
}

- (Class)createChildClassWithKeyPath: (NSString *)keyPath{
    // 2.1. 拼接字符串
    NSString *oldClassName = NSStringFromClass([self class]);
    NSString *newClassName = [NSString stringWithFormat:@"%@%@",kLJKVOPrefix,oldClassName];

    Class newClass = NSClassFromString(newClassName);
    // 2.2 防止重复添加
    if (newClass) {
        return newClass;
    }
    // 2.3 : 申请类
    newClass = objc_allocateClassPair([self class], newClassName.UTF8String, 0);
    // 2.4 注册类
    objc_registerClassPair(newClass);
    
    // 2.4.1 添加Class 方法
    SEL classSEL = NSSelectorFromString(@"class");
    Method classMethod = class_getInstanceMethod([self class], classSEL);
    const char *classTypes = method_getTypeEncoding(classMethod);
    class_addMethod(newClass, classSEL, (IMP)lj_class, classTypes);
    
    // 2.4.2 添加setter 方法
    SEL setterSEL = NSSelectorFromString(setterForGetter(keyPath));
    Method setterMethod = class_getInstanceMethod([self class], setterSEL);
    const char *setterTypes = method_getTypeEncoding(setterMethod);
    class_addMethod(newClass, setterSEL, (IMP)lj_setter, setterTypes);
    
    return newClass;
}

/* 对setter 方法进行字符串微调
 1、添加set字符
 2、首字母大写
 如name 属性，其setter方法为 setName
 */
static NSString *setterForGetter(NSString *getter){
    
    if (getter.length <= 0) { return nil;}
    
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    NSString *leaveString = [getter substringFromIndex:1];
    
    return [NSString stringWithFormat:@"set%@%@:",firstString,leaveString];
}

Class lj_class(id self, SEL _cmd){
    return class_getSuperclass(object_getClass(self));
}


static void lj_setter(id self,SEL _cmd,id newValue){
    NSLog(@"来了:%@",newValue);
    // 4: 消息转发 : 转发给父类
    // 改变父类的值 --- 可以强制类型转换
    NSString *keyPath = getterForSetter(NSStringFromSelector(_cmd));
    id oldValue       = [self valueForKey:keyPath];
    
    void (*lj_msgSendSuper)(void *,SEL , id) = (void *)objc_msgSendSuper;
    // void /* struct objc_super *super, SEL op, ... */
    struct objc_super superStruct = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self)),
    };
    //objc_msgSendSuper(&superStruct,_cmd,newValue)
    lj_msgSendSuper(&superStruct,_cmd,newValue);
    // 1: 拿到观察者
    NSMutableArray *observerArr = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kLJKVOAssiociateKey));
    
    for (LJKVOInfo *info in observerArr) {
        if ([info.keyPath isEqualToString:keyPath]) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSMutableDictionary<NSKeyValueChangeKey,id> *change = [NSMutableDictionary dictionaryWithCapacity:1];
                // 对新旧值进行处理
                if (info.options & LJKeyValueObservingOptionNew) {
                    [change setObject:newValue forKey:NSKeyValueChangeNewKey];
                }
                if (info.options & LJKeyValueObservingOptionOld) {
                    [change setObject:@"" forKey:NSKeyValueChangeOldKey];
                    if (oldValue) {
                        [change setObject:oldValue forKey:NSKeyValueChangeOldKey];
                    }
                }
                // 2: 消息发送给观察者
                SEL observerSEL = @selector(lj_observeValueForKeyPath:ofObject:change:context:);
                objc_msgSend(info.observer,observerSEL,keyPath,self,change,NULL);
            });
        }
    }
    
}

static NSString *getterForSetter(NSString *setter){
    
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) { return nil;}
    
    NSRange range = NSMakeRange(3, setter.length-4);
    NSString *getter = [setter substringWithRange:range];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    return  [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
}
@end
