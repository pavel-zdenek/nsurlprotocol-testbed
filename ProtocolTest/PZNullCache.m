//
//  PZNullCache.m
//  ProtocolTest
//
//  Created by Pavel Zdenek on 8.9.14.
//  Copyright (c) 2014 PZ. All rights reserved.
//

#import "PZNullCache.h"

@implementation PZNullCache

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
  NSLog(@"CACHE GET %@", request.URL.absoluteString);
  return nil;
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse
                 forRequest:(NSURLRequest *)request {
  NSLog(@"CACHE PUT %@", request.URL.absoluteString);
}

@end
