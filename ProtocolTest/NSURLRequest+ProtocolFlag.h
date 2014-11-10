//
//  NSURLRequest+ProtocolFlag.h
//  ProtocolTest
//
//  Created by Pavel Zdeněk on 04/11/14.
//  Copyright (c) 2014 PZ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (ProtocolFlag)

-(BOOL)hasPassedProtocolHandler;

@end

@interface NSMutableURLRequest (ProtocolFlag)

-(void)setPassedProtocolHandler:(BOOL)passed;

@end
