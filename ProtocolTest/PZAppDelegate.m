//
//  PZAppDelegate.m
//  ProtocolTest
//
//  Created by Pavel Zdenek on 29.8.14.
//  Copyright (c) 2014 PZ. All rights reserved.
//

#import "PZAppDelegate.h"
#import "PZProtocolHandler.h"
#import "PZNullCache.h"
#import "SDURLCache.h"

@implementation PZAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [NSURLProtocol registerClass:[PZProtocolHandler class]];
  [NSURLCache setSharedURLCache:[PZNullCache new]];
/*
  SDURLCache* cache = [[SDURLCache alloc] initWithMemoryCapacity:1024*1024
                                                    diskCapacity:1024*1024*5
                                                        diskPath:[SDURLCache defaultCachePath]];
  [NSURLCache setSharedURLCache:cache];
*/
  return YES;
}

@end
