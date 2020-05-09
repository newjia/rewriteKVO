//
//  ViewController.m
//  LJKVO
//
//  Created by 李佳 on 2020/5/8.
//  Copyright © 2020 李佳. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+KVO.h"
#import "Dog.h"
#import <objc/runtime.h>


@interface ViewController ()
@property (strong, nonatomic)  Dog *dog;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dog = [[Dog alloc] init];
    [self.dog lj_addObserver:self forKeyPath:@"petName" options:LJKeyValueObservingOptionNew|LJKeyValueObservingOptionOld context:NULL];
    [self printClassAllMethod:[Dog class]];
    [self printClasses:[Dog class]];
}

- (void)lj_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSLog(@"change      %@", change);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.dog.petName = @"aaa";
}

- (void)dealloc{
    [self.dog lj_removeObserver:self forKeyPath:@"petName"];
}

#pragma mark - 遍历方法-ivar-property
- (void)printClassAllMethod:(Class)cls{
    unsigned int count = 0;
    Method *methodList = class_copyMethodList(cls, &count);
    for (int i = 0; i<count; i++) {
        Method method = methodList[i];
        SEL sel = method_getName(method);
        IMP imp = class_getMethodImplementation(cls, sel);
        NSLog(@"%@-%p",NSStringFromSelector(sel),imp);
    }
    free(methodList);
}

#pragma mark - 遍历类以及子类
- (void)printClasses:(Class)cls{
    
    /// 注册类的总数
    int count = objc_getClassList(NULL, 0);
    /// 创建一个数组， 其中包含给定对象
    NSMutableArray *mArray = [NSMutableArray arrayWithObject:cls];
    /// 获取所有已注册的类
    Class* classes = (Class*)malloc(sizeof(Class)*count);
    objc_getClassList(classes, count);
    for (int i = 0; i<count; i++) {
        if (cls == class_getSuperclass(classes[i])) {
            [mArray addObject:classes[i]];
        }
    }
    free(classes);
    NSLog(@"classes = %@", mArray);
}

@end
