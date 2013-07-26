//
//  RSTLCache.m
//  Cache
//
//  Created by Doug Russell on 7/25/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "RSTLCache.h"
#include <cache.h>
#include <cache_callbacks.h>

#define BVOID __bridge void *
#define BID __bridge id

#pragma mark - Cache Cost Categories

@interface NSObject (rstlcache_cost)

- (NSUInteger)rstlcache_cost;

@end

@implementation NSObject (rstlcache_cost)

- (NSUInteger)rstlcache_cost
{
	return 0;
}

@end

@interface NSString (rstlcache_cost)

@end

@implementation NSString (rstlcache_cost)

- (NSUInteger)rstlcache_cost
{
	return [self length] * sizeof(unichar);
}

@end

@interface NSData (rstlcache_cost)

@end

@implementation NSData (rstlcache_cost)

- (NSUInteger)rstlcache_cost
{
	return [self length];
}

@end

// TODO add UIImage category after checking for ios that returns bytes per row * height for cost

@interface RSTLCache ()
{
@private
	cache_t *_cache;
	bool _notifyOfEvictions;
	bool _willEvictObject;
}
@end

@implementation RSTLCache
@synthesize delegate=_delegate;

#pragma mark - Cache Callbacks

static uintptr_t rstl_cache_key_hash(void *key, void *user_data)
{
	id<NSObject> keyObject = (BID<NSObject>)key;
	NSUInteger hash = [keyObject hash];
	return hash;
}

static bool rstl_cache_key_equal(void *key1, void *key2, void *user_data)
{
	id<NSObject> keyObject1 = (BID<NSObject>)key1;
	id<NSObject> keyObject2 = (BID<NSObject>)key2;
	return [keyObject1 isEqual:keyObject2];
}

static void rstl_cache_key_retain(void *key_in, void **key_out, void *user_data)
{
	*key_out = (void *)CFRetain(key_in);
}

static void rstl_cache_key_release(void *key, void *user_data)
{
	CFRelease(key);
}

static void rstl_cache_value_retain(void *value_in, void *user_data)
{
	CFRetain(value_in);
}

static void rstl_cache_value_release(void *value, void *user_data)
{
	RSTLCache *cache = (BID)user_data;
	if (cache->_notifyOfEvictions)
	{
		id<RSTLCacheDelegate> delegate = cache.delegate;
		if (delegate && cache->_willEvictObject)
		{
			id object = (BID)value;
			[delegate cache:cache willEvictObject:object];
		}
	}
	CFRelease(value);
}

#pragma mark - Setup/Cleanup

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		_notifyOfEvictions = true;
		
		cache_attributes_t attributes;
		attributes.version = CACHE_ATTRIBUTES_VERSION_2;
		
		attributes.key_hash_cb = &rstl_cache_key_hash;
		attributes.key_is_equal_cb = &rstl_cache_key_equal;
		attributes.key_retain_cb = &rstl_cache_key_retain;
		attributes.key_release_cb = &rstl_cache_key_release;
		
		attributes.value_retain_cb = &rstl_cache_value_retain;
		attributes.value_release_cb = &rstl_cache_value_release;
		
		attributes.value_make_nonpurgeable_cb = &cache_value_make_nonpurgeable_cb;
		attributes.value_make_purgeable_cb = &cache_value_make_purgeable_cb;
		
		attributes.user_data = (BVOID)self;
		
		int result = cache_create("com.rstl.cache", &attributes, &_cache);
		if (result)
		{
			return nil;
		}
	}
	return self;
}

- (void)dealloc
{
	_notifyOfEvictions = false;
	if (_cache)
	{
		int result = cache_destroy(_cache);
		if (result == EAGAIN)
		{
			result = cache_destroy(_cache);
			assert(result == 0);
		}
	}
}

#pragma mark - Delegate

- (id<RSTLCacheDelegate>)delegate
{
	return _delegate;
}

- (void)setDelegate:(id<RSTLCacheDelegate>)delegate
{
	if (_delegate != delegate)
	{
		_willEvictObject = [delegate respondsToSelector:@selector(cache:willEvictObject:)];
		_delegate = delegate;
	}
}

#pragma mark - Set

NS_INLINE void setObjectForKey(RSTLCache *cache, id object, id key, NSUInteger cost)
{
	if (!key)
	{
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"BOOM!" userInfo:nil];
	}
	if (!object)
	{
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"BOOM!" userInfo:nil];
	}
	int result = cache_set_and_retain(cache->_cache, (BVOID)key, (BVOID)object, cost);
	assert(result == 0);
	cache_release_value(cache->_cache, (BVOID)object);
}

- (void)setObject:(id)object forKey:(id)key
{
	setObjectForKey(self, object, key, [object rstlcache_cost]);
}

- (void)setObject:(id)object forKey:(id)key cost:(NSUInteger)cost
{
	setObjectForKey(self, object, key, cost);
}

- (void)setObject:(id)object forKeyedSubscript:(id)key
{
	setObjectForKey(self, object, key, [object rstlcache_cost]);
}

#pragma mark - Get

NS_INLINE id objectForKey(RSTLCache *cache, id key)
{
	if (!key)
	{
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"BOOM!" userInfo:nil];
	}
	void *valueOut;
	int result = cache_get_and_retain(cache->_cache, (BVOID)key, &valueOut);
	if (result)
	{
		return nil;
	}
	__strong id object = (BID)valueOut;
	cache_release_value(cache->_cache, valueOut);
	return object;
}

- (id)objectForKey:(id)key
{
	return objectForKey(self, key);
}

- (id)objectForKeyedSubscript:(id)key
{
	return objectForKey(self, key);
}

#pragma mark - Remove

- (void)removeObjectForKey:(id)key
{
	if (!key)
	{
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"BOOM!" userInfo:nil];
	}
	//int result = 
	cache_remove(_cache, (BVOID)key);
}

- (void)removeAllObjects
{
	//int result = 
	cache_remove_all(_cache);
}

@end

#undef BVOID
#undef BID
