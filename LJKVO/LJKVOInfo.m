//
//  LJKVOInfo.m
//  LJKVO
//
//  Created by 李佳 on 2020/5/9.
//  Copyright © 2020 李佳. All rights reserved.
//

#import "LJKVOInfo.h"

@implementation LJKVOInfo

- (instancetype)initWitObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(LJKeyValueObservingOptions)options{
    self = [super init];
    if (self) {
        self.observer = observer;
        self.keyPath  = keyPath;
        self.options  = options;
    }
    return self;
}


@end
