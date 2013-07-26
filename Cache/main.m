//
//  main.m
//  Cache
//
//  Created by Doug Russell on 7/25/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSTLCache.h"

@interface Delegate : NSObject <RSTLCacheDelegate, NSCacheDelegate>

@end

@implementation Delegate

- (void)cache:(id)cache willEvictObject:(id)object
{
	NSLog(@"%@ evicting %@", cache, object);
}

@end

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		RSTLCache *cache = [RSTLCache new];
		Delegate *delegate = [Delegate new];
		CFBridgingRetain(delegate);
		cache.delegate = delegate;
		
		cache[@"foo"] = @"bar";
		id foo = cache[@"foo"];
		NSLog(@"%@", foo);
		
		NSMutableData *data = [NSMutableData new];
		[data setLength:200];
		cache[@"data"] = data;
		
		[cache removeObjectForKey:@"foo"];
	}
	return 0;
}

