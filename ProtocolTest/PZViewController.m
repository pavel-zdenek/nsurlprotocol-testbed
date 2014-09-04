//
//  PZViewController.m
//  ProtocolTest
//
//  Created by Pavel Zdenek on 29.8.14.
//  Copyright (c) 2014 PZ. All rights reserved.
//

#import "PZViewController.h"
#import "PZProtocolHandler.h"


@interface PZViewController () {
  NSDate* _start;
  long _counter;
}

@end

@implementation PZViewController

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.textField setText:@"http://www.rollingstone.com"];
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
  [self.webView loadRequest:
   [NSURLRequest requestWithURL:
    [NSURL URLWithString:self.textField.text]]];
  return YES;
}

#pragma mark - UIWebViewDelegate

-(void)webViewDidStartLoad:(UIWebView *)webView {
  _counter++;
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  self.protocolSwitch.enabled = NO;
  NSTimeInterval elapsed = [[NSDate new] timeIntervalSinceDate:_start];
  self.label.text = [NSString stringWithFormat:@"Started %ld at %.1fs", _counter, elapsed];
  NSLog(@"%@",self.label.text);
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
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

@end
