//
//  PZProtocolHandler.m
//  ProtocolTest
//
//  Created by Pavel Zdenek on 29.8.14.
//  Copyright (c) 2014 PZ. All rights reserved.
//

#import "PZProtocolHandler.h"
#import "NSURLRequest+ProtocolFlag.h"

#undef BYPASS_DELEGATE

@interface PZProtocolHandler () <NSURLConnectionDataDelegate> {
  NSURLConnection* _connection;
}
@end

static NSOperationQueue* _queue;

@implementation PZProtocolHandler

+(void)initialize {
  _queue = [NSOperationQueue new];
  [_queue setMaxConcurrentOperationCount:20];
}

+(BOOL)canInitWithRequest:(NSURLRequest *)request {
  BOOL canNot = [request hasPassedProtocolHandler];
  NSLog(@"CAN %p %u %@", request, !canNot, [[self class] stringShortRequest:request]);
  return !canNot;
}

+(NSURLRequest*)canonicalRequestForRequest:(NSURLRequest *)request {
  return request;
}

-(instancetype)initWithRequest:(NSURLRequest *)request
                cachedResponse:(NSCachedURLResponse *)cachedResponse
                        client:(id<NSURLProtocolClient>)client {
  NSLog(@"INIT %p %@", request, [[self class] stringShortRequest:request]);
  return [super initWithRequest:request
                    cachedResponse:cachedResponse
                         client:client];
}

-(void)startLoading {
  NSLog(@"START %@", [[self class] stringShortRequest:self.request]);
  NSMutableURLRequest* requestMutable = [self.request mutableCopy];
  [requestMutable setPassedProtocolHandler:YES];
#ifdef BYPASS_DELEGATE
  [NSURLConnection sendAsynchronousRequest:requestMutable
                                     queue:_queue
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
  _connection = [[NSURLConnection alloc] initWithRequest:requestMutable
                                                delegate:self
                                        startImmediately:NO];
  // comment out for sure stalling
  [_connection setDelegateQueue:_queue];
  [_connection start];
#endif
}

-(void)stopLoading {
  NSLog(@"STOP %@", self.request);
  [_connection cancel];
  _connection = nil;
}

#pragma mark - NSURLConnectionDataDelegate

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)response {
  if(response == nil) {
    NSLog(@"REDIRECT CANONICAL %p %@", request, [[self class] stringShortRequest:request]);
    return request;
  }
  NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
  NSLog(@"REDIRECT %p %u %@", request, httpResponse.statusCode, [[self class] stringShortRequest:request]);
  [@[@"Location"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSLog(@"HEADER %@ -> %@",obj, httpResponse.allHeaderFields[obj]);
  }];
  NSMutableURLRequest *redirectableRequest = [request mutableCopy];
  // [redirectableRequest setPassedProtocolHandler:NO];
  [self.client URLProtocol:self wasRedirectedToRequest:redirectableRequest redirectResponse:response];
  return redirectableRequest;
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
