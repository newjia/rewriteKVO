//
//  NSObject+KVO.h
//  LJKVO
//
//  Created by 李佳 on 2020/5/8.
//  Copyright © 2020 李佳. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LJKVOInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (KVO)

- (void)lj_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options: (LJKeyValueObservingOptions)options context: (nullable void*)context;

- (void)lj_observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context;

- (void)lj_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
