//
//  PZProtocolHandler.m
//  ProtocolTest
//
//  Created by Pavel Zdenek on 29.8.14.
//  Copyright (c) 2014 PZ. All rights reserved.
//

#import "PZProtocolHandler.h"

#undef BYPASS_DELEGATE

@interface PZProtocolHandler () <NSURLConnectionDataDelegate> {
  NSURLConnection* _connection;
}
@end

static NSString* const PASS_FLAG = @"PassHandlerFlag";

@implementation PZProtocolHandler

+(BOOL)canInitWithRequest:(NSURLRequest *)request {
  BOOL can = ([[self class] propertyForKey:PASS_FLAG inRequest:request] == nil);
  NSLog(@"CAN %u %@", can, [[self class] stringShortRequest:request]);
  return can;
}

+(NSURLRequest*)canonicalRequestForRequest:(NSURLRequest *)request {
  return request;
}

-(instancetype)initWithRequest:(NSURLRequest *)request
                cachedResponse:(NSCachedURLResponse *)cachedResponse
                        client:(id<NSURLProtocolClient>)client {
  NSLog(@"INIT %@", [[self class] stringShortRequest:request]);
  return [super initWithRequest:request
                    cachedResponse:cachedResponse
                         client:client];
}

-(void)startLoading {
  NSLog(@"START %@", [[self class] stringShortRequest:self.request]);
  NSMutableURLRequest* request = [self.request mutableCopy];
  [[self class] setProperty:@(YES) forKey:PASS_FLAG inRequest:request];
  // currentQueue is nil here
  NSOperationQueue* delegateQueue = [NSOperationQueue mainQueue];
#ifdef BYPASS_DELEGATE
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:delegateQueue
                         completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
    // Call the implemented delegate methods for code simplicity.
    // But does not "use" the delegate per se.
    if(error) {
      [self connection:nil didFailWithError:error];
    } else {
      [self connection:nil didReceiveResponse:response];
      [self connection:nil didReceiveData:data];
      [self connectionDidFinishLoading:nil];
    }
  }];
#else
  _connection = [[NSURLConnection alloc] initWithRequest:request
                                                delegate:self
                                        startImmediately:NO];
  // comment out for sure stalling
  [_connection setDelegateQueue:delegateQueue];
  [_connection start];
#endif
}

-(void)stopLoading {
  NSLog(@"STOP %@", [[self class] stringShortRequest:self.request]);
  [_connection cancel];
  _connection = nil;
}

#pragma mark - NSURLConnectionDataDelegate

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)response {
  if( response == nil ) {
    // canonical rewrite
    return request;
  }
  [self.client URLProtocol:self
    wasRedirectedToRequest:request
          redirectResponse:response];
  return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  NSHTTPURLResponse* httpRes = (NSHTTPURLResponse*)response;
  NSLog(@"RESPONSE %ld %@", (long)httpRes.statusCode, [[self class] stringShortRequest:self.request]);
  [self.client URLProtocol:self didReceiveResponse:response
        cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  NSLog(@"DATA %@", [[self class] stringShortRequest:self.request]);
  [self.client URLProtocol:self didLoadData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  NSLog(@"ERR %@", [[self class] stringShortRequest:self.request]);
  [self.client URLProtocol:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  NSLog(@"FINISH %@", [[self class] stringShortRequest:self.request]);
  [self.client URLProtocolDidFinishLoading:self];
}

#pragma mark - private

+(NSString*)stringShortRequest:(NSURLRequest*)request {
  NSURL* url = request.URL;
  url = [[NSURL alloc] initWithScheme:url.scheme
                                 host:url.host
                                 path:url.path ? url.path : @"/"];
  return url.absoluteString;
}
@end
