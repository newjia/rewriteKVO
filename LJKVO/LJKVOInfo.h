//
//  LJKVOInfo.h
//  LJKVO
//
//  Created by 李佳 on 2020/5/9.
//  Copyright © 2020 李佳. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LJKVOInfo : NSObject

typedef NS_OPTIONS(NSUInteger, LJKeyValueObservingOptions) {

    LJKeyValueObservingOptionNew = 0x01,
    LJKeyValueObservingOptionOld = 0x02,
};

@property (nonatomic, weak) NSObject  *observer;
@property (nonatomic, copy) NSString    *keyPath;
@property (nonatomic, assign) LJKeyValueObservingOptions options;

- (instancetype)initWitObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(LJKeyValueObservingOptions)options;

@end

NS_ASSUME_NONNULL_END
