//
//  MacVietKeyManager.m
//  OpenKey
//
//  Created by Tuyen on 1/27/19.
//  Copyright © 2019 360 CORP & VUA HỆ THỐNG. All rights reserved.
//

#import "MacVietKeyManager.h"

extern void MacVietKeyInit(void);

extern CGEventRef MacVietKeyCallback(CGEventTapProxy proxy,
                                  CGEventType type,
                                  CGEventRef event,
                                  void *refcon);

extern NSString* ConvertUtil(NSString* str);

@interface MacVietKeyManager ()

@end

@implementation MacVietKeyManager {

}
static BOOL _isInited = NO;

static CFMachPortRef      eventTap = NULL;
static CGEventMask        eventMask;
static CFRunLoopSourceRef runLoopSource = NULL;
static dispatch_source_t  watchdogTimer = NULL;

+(void)reenableEventTap {
    if (eventTap != NULL) {
        CGEventTapEnable(eventTap, true);
    }
}

+(BOOL)isEventTapEnabled {
    return (eventTap != NULL && CGEventTapIsEnabled(eventTap));
}

+(void)startWatchdog {
    if (watchdogTimer != NULL) return;
    watchdogTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    if (watchdogTimer != NULL) {
        dispatch_source_set_timer(watchdogTimer,
                                  dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
                                  1 * NSEC_PER_SEC,
                                  100 * NSEC_PER_MSEC);
        dispatch_source_set_event_handler(watchdogTimer, ^{
            if (eventTap != NULL && !CGEventTapIsEnabled(eventTap)) {
                NSLog(@"[MacVietKey Watchdog] Re-enabling keyboard event tap");
                CGEventTapEnable(eventTap, true);
            }
        });
        dispatch_resume(watchdogTimer);
    }
}

+(void)stopWatchdog {
    if (watchdogTimer != NULL) {
        dispatch_source_cancel(watchdogTimer);
        watchdogTimer = NULL;
    }
}

+(BOOL)isInited {
    return _isInited;
}

+(BOOL)initEventTap {
    if (_isInited)
        return true;
    
    //init modernKey
    MacVietKeyInit();
    
    // Create an event tap. We are interested in key presses.
    eventMask = ((1 << kCGEventKeyDown) |
                 (1 << kCGEventKeyUp) |
                 (1 << kCGEventFlagsChanged) |
                 (1 << kCGEventLeftMouseDown) |
                 (1 << kCGEventRightMouseDown) |
                 (1 << kCGEventLeftMouseDragged) |
                 (1 << kCGEventRightMouseDragged));
    
    eventTap = CGEventTapCreate(kCGSessionEventTap,
                                kCGHeadInsertEventTap,
                                kCGEventTapOptionDefault,
                                eventMask,
                                MacVietKeyCallback,
                                NULL);
    
    if (!eventTap) {
        
        fprintf(stderr, "failed to create event tap\n");
        return NO;
    }
    
    _isInited = YES;
    
    // Create a run loop source.
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    
    // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    
    // Enable the event tap.
    CGEventTapEnable(eventTap, true);
    [self startWatchdog];
    
    return YES;
}

+(BOOL)stopEventTap {
    [self stopWatchdog];
    if (_isInited) { //release all object
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CFRelease(runLoopSource);
        runLoopSource = nil;
        
        CFMachPortInvalidate(eventTap);
        CFRelease(eventTap);
        eventTap = nil;
        
        _isInited = false;
    }
    return YES;
}

+(NSArray*)getTableCodes {
    return [[NSArray alloc] initWithObjects:
            @"Unicode",
            @"TCVN3 (ABC)",
            @"VNI Windows",
            @"Unicode tổ hợp",
            @"Vietnamese Locale CP 1258", nil];
}

+(NSString*)getBuildDate {
    return [NSString stringWithUTF8String:__DATE__];
}

#pragma mark -Convert feature
+(BOOL)quickConvert {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *htmlString = [pasteboard stringForType:NSPasteboardTypeHTML];
    NSString *rawString = [pasteboard stringForType:NSPasteboardTypeString];
    bool converted = false;
    if (htmlString != nil) {
        htmlString = ConvertUtil(htmlString);
        converted = true;
    }
    if (rawString != nil) {
        rawString = ConvertUtil(rawString);
        converted = true;
    }
    if (converted) {
        [pasteboard clearContents];
        if (htmlString != nil)
            [pasteboard setString:htmlString forType:NSPasteboardTypeHTML];
        if (rawString != nil)
            [pasteboard setString:rawString forType:NSPasteboardTypeString];
        
        return YES;
    }
    return NO;
}

+(void)showMessage:(NSWindow*)window message:(NSString*)msg subMsg:(NSString*)subMsg {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:msg];
    [alert setInformativeText:subMsg];
    [alert addButtonWithTitle:@"OK"];
    if (window) {
        [alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
        }];
    } else {
        [alert runModal];
    }
}

#pragma mark -AutoUpdate feature

+(void)checkNewVersion:(NSWindow*)parent callbackFunc:(CheckNewVersionCallback) callback {
    //load new version config
    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[aSession dataTaskWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/360org/MacVietKey/master/version.json"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            if (data) {
                if(NSClassFromString(@"NSJSONSerialization")) {
                    NSError *error = nil;
                    id object = [NSJSONSerialization
                                 JSONObjectWithData:data
                                 options:0
                                 error:&error];
                    
                    if(error) {  }
                    if([object isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *results = object;
                        NSDictionary *ver = [results valueForKey:@"latestVersion"];
                        NSString* versionCodeString = [ver valueForKey:@"versionCode"];
                        int versionCode = (int)[versionCodeString integerValue];
                        int currentVersionCode = (int)[((NSString*)[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]) integerValue];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (callback != nil) {
                                callback();
                            }
                            if (versionCode > currentVersionCode || callback != nil) {
                                [self showUpdateMessage:parent needUpdating:versionCode > currentVersionCode newVersion:[ver valueForKey:@"versionName"]];
                            }
                        });
                    }
                    else {
                        //oh my god
                    }
                }
                else {
                    //can not parse json
                }
            }
        }
    }] resume];
}

+(void)showUpdateMessage:(NSWindow*)parent needUpdating:(BOOL)needUpdating newVersion:(NSString*)versionString {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:(needUpdating ? [NSString stringWithFormat:@"MacVietKey có phiên bản mới (%@), bạn có muốn cập nhật không?", versionString] : @"Bạn đang dùng phiên bản mới nhất!")];
    [alert setInformativeText:(needUpdating ? @"Bấm 'Có' để tải về và cập nhật MacVietKey ngay lập tức." : @"")];

    if (!needUpdating) {
        [alert addButtonWithTitle:@"OK"];
    } else {
        [alert addButtonWithTitle:@"Có"];
        [alert addButtonWithTitle:@"Không"];
    }
    if (parent == nil) {
        [alert.window makeKeyAndOrderFront:nil];
        [alert.window setLevel:NSStatusWindowLevel];
        NSModalResponse res = [alert runModal];
        if (res == 1000 && needUpdating) {
            [self downloadAndInstallUpdate:versionString];
        }
    } else {
        [alert beginSheetModalForWindow:parent completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == 1000 && needUpdating) {
                [self downloadAndInstallUpdate:versionString];
            }
        }];
    }
}

+(void)downloadAndInstallUpdate:(NSString*)versionString {
    NSString *dmgUrlString = [NSString stringWithFormat:@"https://github.com/360org/MacVietKey/releases/download/v%@/MacVietKey-v%@-macOS.dmg", versionString, versionString];
    NSURL *downloadURL = [NSURL URLWithString:dmgUrlString];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
    NSString *downloadsDirectory = [paths firstObject];
    NSString *targetPath = [downloadsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"MacVietKey-v%@-macOS.dmg", versionString]];

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:downloadURL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (!error && (httpResponse.statusCode == 200 || httpResponse.statusCode == 302)) {
            NSError *fileError = nil;
            NSFileManager *fileManager = [NSFileManager defaultManager];

            if ([fileManager fileExistsAtPath:targetPath]) {
                [fileManager removeItemAtPath:targetPath error:nil];
            }

            [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:targetPath] error:&fileError];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (!fileError) {
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:targetPath]];

                    NSAlert *successAlert = [[NSAlert alloc] init];
                    [successAlert setMessageText:[NSString stringWithFormat:@"Đã tải xong MacVietKey v%@!", versionString]];
                    [successAlert setInformativeText:@"Tệp đĩa ảo .dmg đã được tải vào thư mục Downloads và tự động mở. Bạn chỉ cần kéo biểu tượng MacVietKey vào thư mục Applications để hoàn tất cập nhật."];
                    [successAlert addButtonWithTitle:@"Đã hiểu"];
                    [successAlert runModal];
                } else {
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/360org/MacVietKey/releases/latest"]];
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/360org/MacVietKey/releases/latest"]];
            });
        }
    }];

    [downloadTask resume];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *progressAlert = [[NSAlert alloc] init];
        [progressAlert setMessageText:@"Đang tải bản cập nhật..."];
        [progressAlert setInformativeText:[NSString stringWithFormat:@"MacVietKey v%@ đang được tải tự động vào thư mục Downloads của bạn. Tệp đĩa ảo cài đặt sẽ tự động mở khi hoàn tất.", versionString]];
        [progressAlert addButtonWithTitle:@"Đóng"];
        [progressAlert runModal];
    });
}

+(void)launchUpdateHelper {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/360org/MacVietKey/releases/latest"]];
}

+(NSString*)getApplicationSupportFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    return [NSString stringWithFormat:@"%@/MacVietKey", applicationSupportDirectory];
}

+(NSString*)getUpdateBundlePath {
    NSString *currentpath = [[NSBundle mainBundle] bundlePath];
    return [NSString stringWithFormat:@"%@/Contents/Library/LoginItems/MacVietKeyUpdate.app", currentpath];
}
@end
