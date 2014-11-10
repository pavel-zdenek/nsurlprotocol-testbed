//
//  NSURLRequest+ProtocolFlag.m
//  ProtocolTest
//
//  Created by Pavel Zdeněk on 04/11/14.
//  Copyright (c) 2014 PZ. All rights reserved.
//

#import "NSURLRequest+ProtocolFlag.h"

static NSString *PassThruKey = @"com.salsitasoft.Kitt.ProtocolHandlerPassed";

@implementation NSURLRequest (ProtocolFlag)

-(BOOL)hasPassedProtocolHandler {
/*
  NSDictionary* headers = self.allHTTPHeaderFields;
  [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    NSLog(@"H %@->%@", key, obj);
  }];
  return headers[PassThruKey] != nil;
*/
  return ([NSURLProtocol propertyForKey:PassThruKey inRequest:self] != nil);
}

@end

@implementation NSMutableURLRequest (ProtocolFlag)

-(void)setPassedProtocolHandler:(BOOL)passed {
  //  [self setValue:passed ? @"YES":nil forHTTPHeaderField:PassThruKey];

  if(passed) {
    [NSURLProtocol setProperty:@YES forKey:PassThruKey inRequest:self];
  } else {
    [NSURLProtocol removePropertyForKey:PassThruKey inRequest:self];
  }
}


@end
