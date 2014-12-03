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
#import <MobileCoreServices/MobileCoreServices.h>

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
  [self.textField setText:@"http://novinky.cz"];
  [self.protocolSwitch setOn:YES animated:NO];
}

-(void)onSwitchValueChanged:(id)sender {
  if(self.protocolSwitch.on) {
    [NSURLProtocol registerClass:[PZProtocolHandler class]];
  } else {
    [NSURLProtocol unregisterClass:[PZProtocolHandler class]];
  }
}

-(IBAction)onActivityButtonClicked:(id)sender {
  void(^completeActivityBlock)(NSURL*, NSString*) = ^(NSURL* url, NSString* title){
    NSMutableArray* activityAttachments = [NSMutableArray new];
    NSMutableArray* activityItemsPlain = [NSMutableArray new];
    if(url) {
      [activityAttachments addObject:
        [[NSItemProvider alloc] initWithItem:url typeIdentifier:(__bridge NSString*)kUTTypeURL]
      ];
      [activityItemsPlain addObject:url];
    }
    if([title length]) {
      [activityAttachments addObject:
        [[NSItemProvider alloc] initWithItem:title typeIdentifier:(__bridge NSString*)kUTTypeText]
      ];
      [activityItemsPlain addObject:title];
    }
#ifdef USE_WEBKIT
    /*
     Trying to squeeze the WKWebView instance through to the activity controller in hope that it
     does its magic with Action extension JS execution. Multiple problematic points:
     - WKWebView doesn't implement NSSecureCopying as mandated by NSItemProvider constructor signature
     - UTIs are defined just for primitive data types, not complex objects. Guessing the most generic applicable UTI.
     
     [activityAttachments addObject:
       [[NSItemProvider alloc] initWithItem:_webView typeIdentifier:(__bridge NSString*)kUTTypeContent]
     ];
     */
#endif
    // Seen on
    // https://github.com/AgileBits/onepassword-app-extension/blob/master/OnePasswordExtension.m#L251
    // but doesn't WFM
    NSExtensionItem* activityItem = [[NSExtensionItem alloc] init];
    if([activityAttachments count] > 0) {
      activityItem.attachments = [NSArray arrayWithArray:activityAttachments]; // immutate
      // Wunderlist still doesn't pick up
      activityItem.attributedTitle = [[NSAttributedString alloc] initWithString:title];
    }    
    UIActivityViewController* ctrl = [[UIActivityViewController alloc]
                                       initWithActivityItems:activityItemsPlain
// not WFM initWithActivityItems:@[activityItem]
                                      applicationActivities:nil];
    [self presentViewController:ctrl animated:YES completion:nil];
  };
  
#ifdef USE_WEBKIT
  [_webView evaluateJavaScript:@"document.title" completionHandler:^(id retval, NSError * err) {
    // ignoring error consciously
    completeActivityBlock(_webView.URL, retval);
  }];
#else
  completeActivityBlock(
    _webView.request.URL,
    [_webView stringByEvaluatingJavaScriptFromString:@"document.title"]
  );
#endif
   
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

#ifdef USE_WEBKIT

// Just a minimal delegate set to give some visual loading feedback through the label.
// WKNavigationDelegate declares many other useful callbacks
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                                                     decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  NSLog(@"shouldStartLoad %@", navigationAction.request.URL);
  decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
  NSLog(@"didStartLoad");
  _counter++;
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  self.protocolSwitch.enabled = NO;
  NSTimeInterval elapsed = [[NSDate new] timeIntervalSinceDate:_start];
  self.label.text = [NSString stringWithFormat:@"Started %ld at %.1fs", _counter, elapsed];
  NSLog(@"%@",self.label.text);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  NSLog(@"didFinishLoad");
  _counter--;
  NSTimeInterval elapsed = [[NSDate new] timeIntervalSinceDate:_start];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  self.protocolSwitch.enabled = YES;
  self.label.text = [NSString stringWithFormat:@"Loaded in %.1fs",elapsed];
  NSLog(@"%@",self.label.text);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
  NSLog(@"didFailError %ld", (long)error.code);
}

#else

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

#endif

@end
