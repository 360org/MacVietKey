//
//  AppDelegate.m
//  ModernKey
//
//  Created by Tuyen on 1/18/19.
//  Copyright © 2019 360 CORP & VUA HỆ THỐNG. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>
#include <libproc.h>
#include <sys/proc_info.h>
#import "AppDelegate.h"
#import "ViewController.h"
#import "MacVietKeyManager.h"
#import "MJAccessibilityUtils.h"

AppDelegate* appDelegate;
extern ViewController* viewController;
extern void OnTableCodeChange(void);
extern void OnInputMethodChanged(void);
extern void RequestNewSession(void);
extern void OnActiveAppChanged(void);

//see document in Engine.h
int vLanguage = 1;
int vInputType = 0;
int vFreeMark = 0;
int vCodeTable = 0;
int vCheckSpelling = 1;
int vUseModernOrthography = 1;
int vQuickTelex = 0;
#define DEFAULT_SWITCH_STATUS 0x31000131 //default control + space
int vSwitchKeyStatus = DEFAULT_SWITCH_STATUS;
int vRestoreIfWrongSpelling = 0;
int vFixRecommendBrowser = 1;
int vUseMacro = 1;
int vUseMacroInEnglishMode = 1;
int vAutoCapsMacro = 0;
int vSendKeyStepByStep = 0;
int vUseSmartSwitchKey = 1;
int vUpperCaseFirstChar = 0;
int vTempOffSpelling = 0;
int vAllowConsonantZFWJ = 0;
int vQuickStartConsonant = 0;
int vQuickEndConsonant = 0;
int vRememberCode = 1; //new on version 2.0
int vOtherLanguage = 1; //new on version 2.0
int vTempOffMacVietKey = 0; //new on version 2.0

int vShowIconOnDock = 0; //new on version 2.0

int vPerformLayoutCompat = 0;

//beta feature
int vFixChromiumBrowser = 0; //new on version 2.0

extern int convertToolHotKey;
extern bool convertToolDontAlertWhenCompleted;

@interface AppDelegate ()

@end


@implementation AppDelegate {
    NSWindowController *_mainWC;
    NSWindowController *_macroWC;
    NSWindowController *_convertWC;
    NSWindowController *_aboutWC;
    
    NSStatusItem *statusItem;
    NSMenu *theMenu;
    
    NSMenuItem* menuInputMethod;
    
    NSMenuItem* mnuTelex;
    NSMenuItem* mnuVNI;
    NSMenuItem* mnuSimpleTelex;
    
    NSMenuItem* mnuUnicode;
    NSMenuItem* mnuTCVN;
    NSMenuItem* mnuVNIWindows;
    
    NSMenuItem* mnuUnicodeComposite;
    NSMenuItem* mnuVietnameseLocaleCP1258;
    
    NSMenuItem* mnuQuickConvert;
}

-(void)askPermission {
    NSAlert *alert = [[NSAlert alloc] init];
    NSImage *appIcon = [NSImage imageNamed:@"Icon"];
    if (!appIcon) {
        NSString *iconPath = [[NSBundle mainBundle] pathForResource:@"Icon" ofType:@"icns"];
        if (iconPath) {
            appIcon = [[NSImage alloc] initWithContentsOfFile:iconPath];
        }
    }
    if (appIcon) {
        [alert setIcon:appIcon];
        [NSApp setApplicationIconImage:appIcon];
    }
    [alert setMessageText:@"MacVietKey cần bạn cấp quyền Trợ năng (Accessibility)!"];
    [alert setInformativeText:@"Bật công tắc MacVietKey trong Cài đặt hệ thống (System Settings) để bắt đầu gõ tiếng Việt."];

    [alert addButtonWithTitle:@"Không"];
    [alert addButtonWithTitle:@"Mở Cài Đặt Hệ Thống"];

    [alert.window makeKeyAndOrderFront:nil];
    [alert.window setLevel:NSStatusWindowLevel];

    NSModalResponse res = [alert runModal];

    if (res == 1001) {
        MJAccessibilityOpenPanel();
        // Wait and poll for user enabling permission in System Settings instead of quitting
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (int i = 0; i < 60; i++) {
                [NSThread sleepForTimeInterval:1.0];
                if (MJAccessibilityIsEnabled()) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self continueStartupAfterPermission];
                    });
                    return;
                }
            }
        });
    } else {
        [NSApp terminate:0];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    appDelegate = self;
    NSImage *appIcon = [NSImage imageNamed:@"Icon"];
    if (appIcon) {
        [NSApp setApplicationIconImage:appIcon];
    }
    
    [self registerSupportedNotification];
    
    //set quick tooltip
    [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: 50]
                                              forKey: @"NSInitialToolTipDelay"];
    
    //check whether this app has been launched before that or not
    //Only check instances owned by current user (for multi-user/Fast User Switching support)
    uid_t currentUID = getuid();
    NSArray<NSRunningApplication *>* runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    pid_t myPID = [[NSProcessInfo processInfo] processIdentifier];
    BOOL alreadyRunning = NO;

    for (NSRunningApplication *app in runningApps) {
        if ([app.bundleIdentifier isEqualToString:MACVIETKEY_BUNDLE] &&
            app.processIdentifier != myPID) {
            pid_t pid = app.processIdentifier;
            struct proc_bsdinfo proc;
            int size = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &proc, sizeof(proc));
            if (size == sizeof(proc) && proc.pbi_uid == currentUID) {
                alreadyRunning = YES;
                break;
            }
        }
    }

    if (alreadyRunning) {
        [NSApp terminate:nil];
        return;
    }
    
    // Check Accessibility permission with boot retry to prevent false alarms on system reboot
    [self checkPermissionAndStartup:10];
}

-(void)checkPermissionAndStartup:(int)retriesLeft {
    if (MJAccessibilityIsEnabled()) {
        [self continueStartupAfterPermission];
        return;
    }
    if (retriesLeft > 0) {
        // TCC / WindowServer may still be loading at boot; retry after 500ms
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [self checkPermissionAndStartup:retriesLeft - 1];
        });
        return;
    }
    // Only ask if all retries exhausted
    [self askPermission];
}


-(void)startEventTapQuietly:(int)retriesLeft {
    if ([MacVietKeyManager initEventTap]) {
        NSInteger showui = [[NSUserDefaults standardUserDefaults] integerForKey:@"ShowUIOnStartup"];
        if (showui == 1) {
            [self onControlPanelSelected];
        }
    } else if (retriesLeft > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [self startEventTapQuietly:retriesLeft - 1];
        });
        return;
    } else {
        NSLog(@"[MacVietKey] initEventTap will be monitored by watchdog");
        NSInteger showui = [[NSUserDefaults standardUserDefaults] integerForKey:@"ShowUIOnStartup"];
        if (showui == 1) {
            [self onControlPanelSelected];
        }
    }
    [self setQuickConvertString];
}

-(void)continueStartupAfterPermission {
    vShowIconOnDock = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"vShowIconOnDock"];
    if (vShowIconOnDock)
        [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
    
    if (vSwitchKeyStatus & 0x8000)
        NSBeep();

    [self createStatusBarMenu];
    
    //init with quiet retries; strictly respect ShowUIOnStartup
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startEventTapQuietly:5];
    });
    
    //load default config if is first launch
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"NonFirstTime"] == 0) {
        [self loadDefaultConfig];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"NonFirstTime"];
    
    //check update if enable
    NSInteger dontCheckUpdate = [[NSUserDefaults standardUserDefaults] integerForKey:@"DontCheckUpdate"];
    if (!dontCheckUpdate)
        [MacVietKeyManager checkNewVersion:nil callbackFunc:nil];
    
    //correct run on startup
    NSInteger val = [[NSUserDefaults standardUserDefaults] integerForKey:@"RunOnStartup"];
    [appDelegate setRunOnStartup:val];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    // Menu bar apps (LSUIElement) should only open dashboard if user explicitly enabled Dock icon
    if (vShowIconOnDock && !flag) {
        [self onControlPanelSelected];
    }
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void) createStatusBarMenu {
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    statusItem.button.image = [NSImage imageNamed:@"Status"];
    statusItem.button.alternateImage = [NSImage imageNamed:@"StatusHighlighted"];
    
    theMenu = [[NSMenu alloc] initWithTitle:@""];
    [theMenu setAutoenablesItems:NO];
    
    menuInputMethod = [theMenu addItemWithTitle:@"Bật Tiếng Việt"
                                                     action:@selector(onInputMethodSelected)
                                              keyEquivalent:@""];
    [theMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem* menuInputType = [theMenu addItemWithTitle:@"Kiểu gõ" action:nil keyEquivalent:@""];
    
    [theMenu addItem:[NSMenuItem separatorItem]];
    
    mnuUnicode = [theMenu addItemWithTitle:@"Unicode dựng sẵn" action:@selector(onCodeSelected:) keyEquivalent:@""];
    mnuUnicode.tag = 0;
    mnuTCVN = [theMenu addItemWithTitle:@"TCVN3 (ABC)" action:@selector(onCodeSelected:) keyEquivalent:@""];
    mnuTCVN.tag = 1;
    mnuVNIWindows = [theMenu addItemWithTitle:@"VNI Windows" action:@selector(onCodeSelected:) keyEquivalent:@""];
    mnuVNIWindows.tag = 2;
    NSMenuItem* menuCode = [theMenu addItemWithTitle:@"Bảng mã khác" action:nil keyEquivalent:@""];
    
    [theMenu addItem:[NSMenuItem separatorItem]];
    
    [theMenu addItemWithTitle:@"Công cụ chuyển mã..." action:@selector(onConvertTool) keyEquivalent:@""];
    mnuQuickConvert = [theMenu addItemWithTitle:@"Chuyển mã nhanh" action:@selector(onQuickConvert) keyEquivalent:@""];
    
    [theMenu addItem:[NSMenuItem separatorItem]];
    
    [theMenu addItemWithTitle:@"Bảng điều khiển..." action:@selector(onControlPanelSelected) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Gõ tắt..." action:@selector(onMacroSelected) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Giới thiệu" action:@selector(onAboutSelected) keyEquivalent:@""];
    [theMenu addItem:[NSMenuItem separatorItem]];
    
    [theMenu addItemWithTitle:@"Thoát" action:@selector(terminate:) keyEquivalent:@"q"];
    
    
    [self setInputTypeMenu:menuInputType];
    [self setCodeMenu:menuCode];
    
    //set menu
    [statusItem setMenu:theMenu];
    
    [self fillData];
}

-(void)setQuickConvertString {
    NSMutableString* hotKey = [NSMutableString stringWithString:@""];
    bool hasAdd = false;
    if (convertToolHotKey & 0x100) {
        [hotKey appendString:@"⌃"];
        hasAdd = true;
    }
    if (convertToolHotKey & 0x200) {
        if (hasAdd)
            [hotKey appendString:@" + "];
        [hotKey appendString:@"⌥"];
        hasAdd = true;
    }
    if (convertToolHotKey & 0x400) {
        if (hasAdd)
            [hotKey appendString:@" + "];
        [hotKey appendString:@"⌘"];
        hasAdd = true;
    }
    if (convertToolHotKey & 0x800) {
        if (hasAdd)
            [hotKey appendString:@" + "];
        [hotKey appendString:@"⇧"];
        hasAdd = true;
    }
    
    unsigned short k = ((convertToolHotKey>>24) & 0xFF);
    if (k != 0xFE) {
        if (hasAdd)
            [hotKey appendString:@" + "];
        if (k == kVK_Space)
            [hotKey appendFormat:@"%@", @"␣ "];
        else
            [hotKey appendFormat:@"%c", k];
    }
    [mnuQuickConvert setTitle: hasAdd ? [NSString stringWithFormat:@"Chuyển mã nhanh - [%@]", [hotKey uppercaseString]] : @"Chuyển mã nhanh"];
}

-(void)loadDefaultConfig {
    vLanguage = 1; [[NSUserDefaults standardUserDefaults] setInteger:vLanguage forKey:@"InputMethod"];
    vInputType = 0; [[NSUserDefaults standardUserDefaults] setInteger:vInputType forKey:@"InputType"];
    vFreeMark = 0; [[NSUserDefaults standardUserDefaults] setInteger:vFreeMark forKey:@"FreeMark"];
    vCheckSpelling = 1; [[NSUserDefaults standardUserDefaults] setInteger:vCheckSpelling forKey:@"Spelling"];
    vCodeTable = 0; [[NSUserDefaults standardUserDefaults] setInteger:vCodeTable forKey:@"CodeTable"];
    vSwitchKeyStatus = DEFAULT_SWITCH_STATUS; [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
    vQuickTelex = 0; [[NSUserDefaults standardUserDefaults] setInteger:vQuickTelex forKey:@"QuickTelex"];
    vUseModernOrthography = 0; [[NSUserDefaults standardUserDefaults] setInteger:vUseModernOrthography forKey:@"ModernOrthography"];
    vRestoreIfWrongSpelling = 0; [[NSUserDefaults standardUserDefaults] setInteger:vRestoreIfWrongSpelling forKey:@"RestoreIfInvalidWord"];
    vFixRecommendBrowser = 1; [[NSUserDefaults standardUserDefaults] setInteger:vFixRecommendBrowser forKey:@"FixRecommendBrowser"];
    vUseMacro = 1; [[NSUserDefaults standardUserDefaults] setInteger:vUseMacro forKey:@"UseMacro"];
    vUseMacroInEnglishMode = 0; [[NSUserDefaults standardUserDefaults] setInteger:vUseMacroInEnglishMode forKey:@"UseMacroInEnglishMode"];
    vSendKeyStepByStep = 0;[[NSUserDefaults standardUserDefaults] setInteger:vUseMacroInEnglishMode forKey:@"SendKeyStepByStep"];
    vUseSmartSwitchKey = 1;[[NSUserDefaults standardUserDefaults] setInteger:vUseSmartSwitchKey forKey:@"UseSmartSwitchKey"];
    vUpperCaseFirstChar = 0;[[NSUserDefaults standardUserDefaults] setInteger:vUpperCaseFirstChar forKey:@"UpperCaseFirstChar"];
    vTempOffSpelling = 0;[[NSUserDefaults standardUserDefaults] setInteger:vTempOffSpelling forKey:@"vTempOffSpelling"];
    vAllowConsonantZFWJ = 0;[[NSUserDefaults standardUserDefaults] setInteger:vAllowConsonantZFWJ forKey:@"vAllowConsonantZFWJ"];
    vQuickStartConsonant = 0;[[NSUserDefaults standardUserDefaults] setInteger:vQuickStartConsonant forKey:@"vQuickStartConsonant"];
    vQuickEndConsonant = 0;[[NSUserDefaults standardUserDefaults] setInteger:vQuickEndConsonant forKey:@"vQuickEndConsonant"];
    vRememberCode = 1;[[NSUserDefaults standardUserDefaults] setInteger:vRememberCode forKey:@"vRememberCode"];
    vOtherLanguage = 1;[[NSUserDefaults standardUserDefaults] setInteger:vOtherLanguage forKey:@"vOtherLanguage"];
    vTempOffMacVietKey = 0;[[NSUserDefaults standardUserDefaults] setInteger:vTempOffMacVietKey forKey:@"vTempOffMacVietKey"];
    vShowIconOnDock = 0;[[NSUserDefaults standardUserDefaults] setInteger:vShowIconOnDock forKey:@"vShowIconOnDock"];
    vFixChromiumBrowser = 0;[[NSUserDefaults standardUserDefaults] setInteger:vFixChromiumBrowser forKey:@"vFixChromiumBrowser"];
    vPerformLayoutCompat = 0;[[NSUserDefaults standardUserDefaults] setInteger:vPerformLayoutCompat forKey:@"vPerformLayoutCompat"];

    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"GrayIcon"];
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"RunOnStartup"];

    [self fillData];
    [viewController fillData];
}

-(NSString *)launchAgentPlistPath {
    NSString *home = NSHomeDirectory();
    return [NSString stringWithFormat:@"%@/Library/LaunchAgents/com.vuahethong.vuaoffice.macvietkey.plist", home];
}

-(void)manageLaunchAgent:(BOOL)enable {
    NSString *plistPath = [self launchAgentPlistPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (enable) {
        NSString *launchAgentsDir = [plistPath stringByDeletingLastPathComponent];
        if (![fm fileExistsAtPath:launchAgentsDir]) {
            [fm createDirectoryAtPath:launchAgentsDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSString *appPath = [[NSBundle mainBundle] bundlePath];
        if (!appPath || [appPath length] == 0) {
            appPath = @"/Applications/MacVietKey.app";
        }
        
        NSString *binPath = [appPath stringByAppendingPathComponent:@"Contents/MacOS/MacVietKey"];
        NSArray *args;
        if ([fm fileExistsAtPath:binPath]) {
            args = @[binPath];
        } else {
            args = @[@"/usr/bin/open", @"-g", @"-j", @"-a", appPath];
        }
        NSDictionary *dict = @{
            @"Label": @"com.vuahethong.vuaoffice.macvietkey",
            @"ProgramArguments": args,
            @"RunAtLoad": @YES,
            @"ProcessType": @"Interactive"
        };
        
        [dict writeToFile:plistPath atomically:YES];
        NSLog(@"[MacVietKey] LaunchAgent enabled at: %@", plistPath);
    } else {
        if ([fm fileExistsAtPath:plistPath]) {
            [fm removeItemAtPath:plistPath error:nil];
            NSLog(@"[MacVietKey] LaunchAgent removed from: %@", plistPath);
        }
    }
}

-(void)setRunOnStartup:(BOOL)val {
    // 1. LaunchAgent for 100% reliability across all macOS versions
    [self manageLaunchAgent:val];
    
    // 2. Modern SMAppService for native macOS 13+ (Ventura, Sonoma, Sequoia)
    if (@available(macOS 13.0, *)) {
        SMAppService *service = [SMAppService mainAppService];
        NSError *error = nil;
        if (val) {
            if (service.status != SMAppServiceStatusEnabled) {
                BOOL ok = [service registerAndReturnError:&error];
                if (!ok) {
                    NSLog(@"[MacVietKey] SMAppService register note: %@", error);
                }
            }
        } else {
            if (service.status == SMAppServiceStatusEnabled) {
                [service unregisterAndReturnError:&error];
            }
        }
    }
    
    // 3. Legacy embedded login item helper fallback
    CFStringRef appId = (__bridge CFStringRef)@"com.vuahethong.vuaoffice.macvietkey.helper";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    SMLoginItemSetEnabled(appId, val);
#pragma clang diagnostic pop
}

-(void)setGrayIcon:(BOOL)val {
    [self fillData];
}

-(void)showIconOnDock:(BOOL)val {
    [NSApp setActivationPolicy: val ? NSApplicationActivationPolicyRegular : NSApplicationActivationPolicyAccessory];
}

#pragma mark -StatusBar menu data

- (void)setInputTypeMenu:(NSMenuItem*) parent {
    //sub for Kieu Go
    NSMenu *sub = [[NSMenu alloc] initWithTitle:@""];
    [sub setAutoenablesItems:NO];
    mnuTelex = [sub addItemWithTitle:@"Telex" action:@selector(onInputTypeSelected:) keyEquivalent:@""];
    mnuTelex.tag = 0;
    mnuVNI = [sub addItemWithTitle:@"VNI" action:@selector(onInputTypeSelected:) keyEquivalent:@""];
    mnuVNI.tag = 1;
    mnuSimpleTelex = [sub addItemWithTitle:@"Simple Telex" action:@selector(onInputTypeSelected:) keyEquivalent:@""];
    mnuSimpleTelex.tag = 2;
    [theMenu setSubmenu:sub forItem:parent];
}

- (void)setCodeMenu:(NSMenuItem*) parent {
    //sub for Code
    NSMenu *sub = [[NSMenu alloc] initWithTitle:@""];
    [sub setAutoenablesItems:NO];
    mnuUnicodeComposite = [sub addItemWithTitle:@"Unicode tổ hợp" action:@selector(onCodeSelected:) keyEquivalent:@""];
    mnuUnicodeComposite.tag = 3;
    mnuVietnameseLocaleCP1258 = [sub addItemWithTitle:@"Vietnamese Locale CP 1258" action:@selector(onCodeSelected:) keyEquivalent:@""];
    mnuVietnameseLocaleCP1258.tag = 4;
    
    [theMenu setSubmenu:sub forItem:parent];
}

- (void) fillData {
    //fill data
    NSInteger intInputMethod = [[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"];
    NSInteger grayIcon = [[NSUserDefaults standardUserDefaults] integerForKey:@"GrayIcon"];
    if (intInputMethod == 1) {
        [menuInputMethod setState:NSControlStateValueOn];
        statusItem.button.image = [NSImage imageNamed:@"Status"];
        [statusItem.button.image setTemplate:(grayIcon ? YES : NO)];
        statusItem.button.alternateImage = [NSImage imageNamed:@"StatusHighlighted"];
    } else {
        [menuInputMethod setState:NSControlStateValueOff];
        statusItem.button.image = [NSImage imageNamed:@"StatusEng"];
        [statusItem.button.image setTemplate:(grayIcon ? YES : NO)];
        statusItem.button.alternateImage = [NSImage imageNamed:@"StatusHighlightedEng"];
    }
    vLanguage = (int)intInputMethod;
    
    NSInteger intInputType = [[NSUserDefaults standardUserDefaults] integerForKey:@"InputType"];
    [mnuTelex setState:NSControlStateValueOff];
    [mnuVNI setState:NSControlStateValueOff];
    [mnuSimpleTelex setState:NSControlStateValueOff];
    if (intInputType == 0) {
        [mnuTelex setState:NSControlStateValueOn];
        vInputType = 0;
    } else if (intInputType == 1) {
        [mnuVNI setState:NSControlStateValueOn];
        vInputType = 1;
    } else {
        [mnuSimpleTelex setState:NSControlStateValueOn];
        vInputType = 3; // vSimpleTelex2: standard Unikey/EVKey Simple Telex (w -> ư, brackets literal)
    }
    
    NSInteger intSwitchKeyStatus = [[NSUserDefaults standardUserDefaults] integerForKey:@"SwitchKeyStatus"];
    vSwitchKeyStatus = (int)intSwitchKeyStatus;
    if (vSwitchKeyStatus == 0)
        vSwitchKeyStatus = DEFAULT_SWITCH_STATUS;
    
    NSInteger intCode = [[NSUserDefaults standardUserDefaults] integerForKey:@"CodeTable"];
    [mnuUnicode setState:NSControlStateValueOff];
    [mnuTCVN setState:NSControlStateValueOff];
    [mnuVNIWindows setState:NSControlStateValueOff];
    [mnuUnicodeComposite setState:NSControlStateValueOff];
    [mnuVietnameseLocaleCP1258 setState:NSControlStateValueOff];
    if (intCode == 0) {
        [mnuUnicode setState:NSControlStateValueOn];
    } else if (intCode == 1) {
        [mnuTCVN setState:NSControlStateValueOn];
    } else if (intCode == 2) {
        [mnuVNIWindows setState:NSControlStateValueOn];
    } else if (intCode == 3) {
        [mnuUnicodeComposite setState:NSControlStateValueOn];
    } else if (intCode == 4) {
        [mnuVietnameseLocaleCP1258 setState:NSControlStateValueOn];
    }
    vCodeTable = (int)intCode;
    
    //
    NSInteger intRunOnStartup = [[NSUserDefaults standardUserDefaults] integerForKey:@"RunOnStartup"];
    [self setRunOnStartup:intRunOnStartup ? YES : NO];

}

-(void)onImputMethodChanged:(BOOL)willNotify {
    NSInteger intInputMethod = [[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"];
    if (intInputMethod == 0)
        intInputMethod = 1;
    else
        intInputMethod = 0;
    vLanguage = (int)intInputMethod;
    [[NSUserDefaults standardUserDefaults] setInteger:intInputMethod forKey:@"InputMethod"];

    [self fillData];
    [viewController fillData];
    
    if (willNotify)
        OnInputMethodChanged();
}

#pragma mark -StatusBar menu action
- (void)onInputMethodSelected {
    [self onImputMethodChanged:YES];
}

- (void)onInputTypeSelected:(id)sender {
    NSMenuItem *menuItem = (NSMenuItem*) sender;
    [self onInputTypeSelectedIndex:(int)menuItem.tag];
}

- (void)onInputTypeSelectedIndex:(int)index {
    int engineType = (index >= 2) ? 3 : index; // 2 -> vSimpleTelex2 (Standard Simple Telex)
    [[NSUserDefaults standardUserDefaults] setInteger:engineType forKey:@"InputType"];
    vInputType = engineType;
    [self fillData];
    [viewController fillData];
}

- (void)onCodeTableChanged:(int)index {
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"CodeTable"];
    vCodeTable = index;
    [self fillData];
    [viewController fillData];
    OnTableCodeChange();
}

- (void)onCodeSelected:(id)sender {
    NSMenuItem *menuItem = (NSMenuItem*) sender;
    [self onCodeTableChanged:(int)menuItem.tag];
}

-(void)onConvertTool {
    if (_convertWC == nil) {
        _convertWC = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"ConvertWindow"];
    }
    //[MacVietKeyManager showDockIcon:YES];
    if ([_convertWC.window isVisible])
        return;
    [_convertWC.window makeKeyAndOrderFront:nil];
    [_convertWC.window setLevel:NSFloatingWindowLevel];
    [NSApp activateIgnoringOtherApps:YES];
}

-(void)onQuickConvert {
    if ([MacVietKeyManager quickConvert]) {
        if (!convertToolDontAlertWhenCompleted) {
            [MacVietKeyManager showMessage: nil message:@"Chuyển mã thành công!" subMsg:@"Kết quả đã được lưu trong clipboard."];
        }
    } else {
        [MacVietKeyManager showMessage: nil message:@"Không có dữ liệu trong clipboard!" subMsg:@"Hãy sao chép một đoạn text để chuyển đổi!"];
    }
}

-(void) onControlPanelSelected {
    if (_mainWC == nil) {
        @try {
            _mainWC = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"MacVietKey"];
        } @catch (NSException *e) {
            @try {
                _mainWC = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"OpenKey"];
            } @catch (NSException *e2) {
                NSLog(@"Failed to instantiate control panel window: %@", e2);
            }
        }
    }
    if (_mainWC != nil) {
        [_mainWC.window makeKeyAndOrderFront:nil];
        [_mainWC.window setLevel:NSFloatingWindowLevel];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

-(void) onMacroSelected {
    if (_macroWC == nil) {
        _macroWC = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"MacroWindow"];
    }
    //[MacVietKeyManager showDockIcon:YES];
    if ([_macroWC.window isVisible])
        return;
    
    [_macroWC.window makeKeyAndOrderFront:nil];
    [_macroWC.window setLevel:NSFloatingWindowLevel];
    [NSApp activateIgnoringOtherApps:YES];
}

-(void) onAboutSelected {
    if (_aboutWC == nil) {
        _aboutWC = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"AboutWindow"];
    }
    //[MacVietKeyManager showDockIcon:YES];
    if ([_aboutWC.window isVisible])
        return;

    [_aboutWC.window makeKeyAndOrderFront:nil];
    [_aboutWC.window setLevel:NSFloatingWindowLevel];
    [NSApp activateIgnoringOtherApps:YES];
}

#pragma mark -Short key event
-(void)onSwitchLanguage {
    [self onInputMethodSelected];
    [viewController fillData];
}

#pragma mark Reset MacVietKey after mac computer awake
-(void)receiveWakeNote: (NSNotification*)note {
    [MacVietKeyManager initEventTap];
}

-(void)receiveSleepNote: (NSNotification*)note {
    [MacVietKeyManager stopEventTap];
}

-(void)receiveActiveSpaceChanged: (NSNotification*)note {
    RequestNewSession();
}

-(void)activeAppChanged: (NSNotification*)note {
    extern void queryFrontMostApp(void);
    queryFrontMostApp();
    if (vUseSmartSwitchKey && [MacVietKeyManager isInited]) {
        OnActiveAppChanged();
    }
}

-(void)registerSupportedNotification {
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveSleepNote:)
                                                               name: NSWorkspaceWillSleepNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveActiveSpaceChanged:)
                                                               name: NSWorkspaceActiveSpaceDidChangeNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(activeAppChanged:)
                                                               name: NSWorkspaceDidActivateApplicationNotification object: NULL];
}
@end
