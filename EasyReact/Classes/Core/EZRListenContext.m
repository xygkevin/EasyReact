/**
 * Beijing Sankuai Online Technology Co.,Ltd (Meituan)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

#import "EZRListenContext.h"
#import "EZRListenContext+ProjectPrivate.h"
#import "EZRNode+ProjectPrivate.h"
#import "EZRCancelableBagProtocol.h"
#import "EZRBlockListenTransform.h"
#import "EZRBlockDeliveredListenTransform.h"
#import "EZRListenTransform.h"
#import "EZRBlockCancelable.h"
#import "EZRListenTransformProtocol.h"
#import "NSObject+EZR_Listen.h"

@implementation EZRListenContext {
    __weak EZRNode *_node;
    __weak id _listener;
    NSMutableArray<id<EZRListenTransformProtocol>> *_transforms;
}

- (instancetype)initWithNode:(__weak EZRNode *)node listener:(__weak id)listener {
    if (self = [super init]) {
        _node = node;
        _listener = listener;
        _transforms = [NSMutableArray array];
    }
    return self;
}

- (id<EZRCancelable>)withBlock:(void (^)(id _Nullable next))block {
    NSParameterAssert(block);
    EZRListenBlockType contextBlock = ^(id next, id context) {
        if (block) {
            block(next);
        }
    };
    return [self withContextBlock:contextBlock];
}

- (id<EZRCancelable>)withContextBlock:(void (^)(id _Nullable, id _Nullable))block {
    NSParameterAssert(block);
    if (!block) {
        return [[EZRBlockCancelable alloc] initWithBlock:^{}];
    }
    EZRBlockListenTransform *handler = [[EZRBlockListenTransform alloc] initWithBlock:block];
    return [self withListenTransform:handler];
}

- (id<EZRCancelable>)withBlock:(void (^)(id _Nullable))block on:(dispatch_queue_t)queue {
    NSParameterAssert(block);
    NSParameterAssert(queue);
    EZRListenBlockType contextBlock = ^(id next, id context) {
        if (block) {
            block(next);
        }
    };
    return [self withContextBlock:contextBlock on:queue];
}

- (id<EZRCancelable>)withContextBlock:(void (^)(id _Nullable, id _Nullable))block on:(dispatch_queue_t)queue {
    NSParameterAssert(block);
    NSParameterAssert(queue);
    if (block && queue) {
        EZRBlockDeliveredListenTransform *handler = [[EZRBlockDeliveredListenTransform alloc] initWithBlock:block on:queue];
        return [self withListenTransform:handler];
    }
    return [[EZRBlockCancelable alloc] initWithBlock:^{}];
}

- (id<EZRCancelable>)withBlockOnMainQueue:(void (^)(id _Nullable))block {
    return [self withBlock:block on:dispatch_get_main_queue()];
}

- (id<EZRCancelable>)withContextBlockOnMainQueue:(void (^)(id _Nullable, id _Nullable))block {
    return [self withContextBlock:block on:dispatch_get_main_queue()];
}

- (id<EZRCancelable>)withListenTransform:(id<EZRListenTransformProtocol>)listenTransform {
    NSParameterAssert(listenTransform);
    EZRNode *strongNode = _node;
    if (listenTransform && strongNode) {
        listenTransform.from = strongNode;
        listenTransform.to = _listener;
        [_transforms addObject:listenTransform];
        return [[EZRBlockCancelable alloc] initWithBlock:^{
            listenTransform.from = nil;
            listenTransform.to = nil;
            [self->_transforms removeObject:listenTransform];
            if (self->_transforms.count == 0) {
                [self->_listener stopListen:strongNode];
            }
        }];
    }
    return [[EZRBlockCancelable alloc] initWithBlock:^{
        
    }];
}

@end