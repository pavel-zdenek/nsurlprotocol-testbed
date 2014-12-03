//
//  PZViewController.h
//  ProtocolTest
//
//  Created by Pavel Zdenek on 29.8.14.
//  Copyright (c) 2014 PZ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WKWebView.h>

@interface PZViewController : UIViewController<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField* textField;
@property (nonatomic, weak) IBOutlet UILabel* label;
@property (nonatomic, weak) IBOutlet UIView* viewForWebView;
@property (nonatomic, weak) IBOutlet UISwitch* protocolSwitch;

-(IBAction)onSwitchValueChanged:(id)sender;
-(IBAction)onActivityButtonClicked:(id)sender;

@end
