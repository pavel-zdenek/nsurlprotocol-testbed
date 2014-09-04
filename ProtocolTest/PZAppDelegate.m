//
//  PZAppDelegate.m
//  ProtocolTest
//
//  Created by Pavel Zdenek on 29.8.14.
//  Copyright (c) 2014 PZ. All rights reserved.
//

#import "PZAppDelegate.h"
#import "PZProtocolHandler.h"

@implementation PZAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Override point for customization after application launch.
  [NSURLProtocol registerClass:[PZProtocolHandler class]];
  return YES;
}

@end
