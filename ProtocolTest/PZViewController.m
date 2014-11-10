//
//  PZViewController.m
//  ProtocolTest
//
//  Created by Pavel Zdenek on 29.8.14.
//  Copyright (c) 2014 PZ. All rights reserved.
//

#import "PZViewController.h"
#import "PZProtocolHandler.h"
#ifdef USE_WEBKIT
#import <WebKit/WebKit.h>
#define WEBVIEW_CLASS WKWebView
#else
#define WEBVIEW_CLASS UIWebView
#endif

@interface PZViewController () <
#ifdef USE_WEBKIT
WKNavigationDelegate
#else
UIWebViewDelegate
#endif
>
@end

@implementation PZViewController
{
  NSDate* _start;
  long _counter;
  WEBVIEW_CLASS *_webView;
}

-(void)viewDidLoad {
  _webView = [[WEBVIEW_CLASS alloc] initWithFrame:self.viewForWebView.bounds];
#ifdef USE_WEBKIT
  _webView.navigationDelegate = self;
#else
  _webView.delegate = self;
#endif
  [self.viewForWebView addSubview:_webView];
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.textField setText:@"http://clojure.org"];
  [self.protocolSwitch setOn:YES animated:NO];
}

-(void)onSwitchValueChanged:(id)sender {
  if(self.protocolSwitch.on) {
    [NSURLProtocol registerClass:[PZProtocolHandler class]];
  } else {
    [NSURLProtocol unregisterClass:[PZProtocolHandler class]];
  }
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  _counter = 0;
  _start = [NSDate new];
  self.label.text = @"";
  [_webView loadRequest:
   [NSURLRequest requestWithURL:
    [NSURL URLWithString:self.textField.text]]];
  return YES;
}

#pragma mark - UIWebViewDelegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
navigationType:(UIWebViewNavigationType)navigationType {
  NSLog(@"shouldStartLoad %@", request.URL);
  return YES;
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
   NSLog(@"didStartLoad");
  _counter++;
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  self.protocolSwitch.enabled = NO;
  NSTimeInterval elapsed = [[NSDate new] timeIntervalSinceDate:_start];
  self.label.text = [NSString stringWithFormat:@"Started %ld at %.1fs", _counter, elapsed];
  NSLog(@"%@",self.label.text);
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
  NSLog(@"didFinishLoad");
  _counter--;
  NSTimeInterval elapsed = [[NSDate new] timeIntervalSinceDate:_start];
  if(_counter == 0) {
    // This is not exactly right because zero running webView loads doesn't mean
    // that loading is finished (more may come) but some cut off is needed even
    // if it happens multiple times over one load
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.protocolSwitch.enabled = YES;
    self.label.text = [NSString stringWithFormat:@"Loaded in %.1fs",elapsed];
  } else {
    self.label.text = [NSString stringWithFormat:@"Finished %ld at %.1fs", _counter, elapsed];
  }
  NSLog(@"%@",self.label.text);
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  NSLog(@"didFailError %ld", (long)error.code);
}

@end
