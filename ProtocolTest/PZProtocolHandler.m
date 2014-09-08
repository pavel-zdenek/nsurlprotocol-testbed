//
//  PZProtocolHandler.m
//  ProtocolTest
//
//  Created by Pavel Zdenek on 29.8.14.
//  Copyright (c) 2014 PZ. All rights reserved.
//

#import "PZProtocolHandler.h"

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

+(NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
  NSLog(@"CANONICAL %@", request.URL.absoluteString);
  return request;
}

+(BOOL)requestIsCacheEquivalent:(NSURLRequest *)a
                       toRequest:(NSURLRequest *)b
{
  NSLog(@"CACHE EQUIV %@ %@", a.URL.absoluteString, b.URL.absoluteString);
  return NO;
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
  request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
  [[self class] setProperty:@(YES) forKey:PASS_FLAG inRequest:request];
  _connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

-(void)stopLoading {
  NSLog(@"STOP %@", [[self class] stringShortRequest:self.request]);
  [_connection cancel];
}

#pragma mark - NSURLConnectionDataDelegate


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse {

  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)[cachedResponse response];
  // Look up the cache policy used in our request
  if([connection currentRequest].cachePolicy == NSURLRequestUseProtocolCachePolicy) {
    NSDictionary *headers = [httpResponse allHeaderFields];
    if(!(headers[@"Cache-Control"] || headers[@"Expires"])) {
      NSLog(@"CACHE DENY %@", httpResponse.URL.absoluteString);
      return nil; // don't cache this
    }
  }
  return cachedResponse;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  NSHTTPURLResponse* httpRes = (NSHTTPURLResponse*)response;
  NSLog(@"RESPONSE %d %@", httpRes.statusCode, [[self class] stringShortRequest:self.request]);
  [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
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
