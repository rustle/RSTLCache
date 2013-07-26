//
//  RSTLCache.h
//  Cache
//
//  Created by Doug Russell on 7/25/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RSTLCacheDelegate;

@interface RSTLCache : NSObject

@property (weak) id<RSTLCacheDelegate> delegate;

- (id)objectForKey:(id)key;
- (void)setObject:(id)object forKey:(id)key;
- (void)setObject:(id)object forKey:(id)key cost:(NSUInteger)cost;

- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(id)key;

- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;

@end

@protocol RSTLCacheDelegate <NSObject>
@optional
- (void)cache:(RSTLCache *)cache willEvictObject:(id)object;
@end
