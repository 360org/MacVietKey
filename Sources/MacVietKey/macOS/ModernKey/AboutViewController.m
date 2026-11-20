//
//  AboutViewController.m
//  MacVietKey
//
//  Created by 360 CORP on 2026.
//  Copyright © 2026 360 CORP & VUA HỆ THỐNG. All rights reserved.
//

#import "AboutViewController.h"
#import "MacVietKeyManager.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)updateLabelsInView:(NSView *)view {
    for (NSView *sub in view.subviews) {
        if ([sub isKindOfClass:[NSTextField class]]) {
            NSTextField *tf = (NSTextField *)sub;
            NSString *val = tf.stringValue;
            if ([val isEqualToString:@"OpenKey"]) {
                tf.stringValue = @"MacVietKey";
            } else if ([val containsString:@"tuyenvm/OpenKey/releases"]) {
                tf.stringValue = @"https://github.com/360org/MacVietKey/releases";
            } else if ([val containsString:@"tuyenvm/OpenKey"]) {
                tf.stringValue = @"https://github.com/360org/MacVietKey";
            } else if ([val containsString:@"OpenKeyVN"]) {
                tf.stringValue = @"https://vuaoffice.com";
            } else if ([val containsString:@"Mai Vũ Tuyên"] || [val containsString:@"2019"]) {
                tf.stringValue = @"360 CORP & VUA HỆ THỐNG © 2026";
            } else if ([val containsString:@"OpenKey"]) {
                tf.stringValue = [val stringByReplacingOccurrencesOfString:@"OpenKey" withString:@"MacVietKey"];
            }
        }
        [self updateLabelsInView:sub];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateLabelsInView:self.view];
    
    self.VersionInfo.stringValue = [NSString stringWithFormat:@"Phiên bản %@ (build %@) - Ngày cập nhật %@",
                                    [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                    [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"],
                                    [MacVietKeyManager getBuildDate]];
    
    NSInteger dontCheckUpdate = [[NSUserDefaults standardUserDefaults] integerForKey:@"DontCheckUpdate"];
    self.CheckUpdateOnStatus.state = dontCheckUpdate ? NSControlStateValueOff : NSControlStateValueOn;
}

- (IBAction)onHomePage:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://github.com/360org/MacVietKey"]];
}

- (IBAction)onFanPage:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://vuaoffice.com"]];
}

- (IBAction)onLatestReleaseVersion:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://github.com/360org/MacVietKey/releases"]];
}

- (IBAction)onCheckUpdateOnStartup:(NSButton *)sender {
    NSInteger val = sender.state == NSControlStateValueOn ? 0 : 1;
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:@"DontCheckUpdate"];
}

- (IBAction)onCheckNewVersion:(id)sender {
    self.CheckNewVersionButton.title = @"Đang kiểm tra...";
    self.CheckNewVersionButton.enabled = false;
    
    [MacVietKeyManager checkNewVersion: self.view.window callbackFunc:^{
        self.CheckNewVersionButton.enabled = true;
        self.CheckNewVersionButton.title = @"Kiểm tra bản mới...";
    }];
}

@end
