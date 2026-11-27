//
//  MacVietKeyManager.m
//  MacVietKey
//
//  Created by Tuyen on 1/27/19.
//  Copyright © 2026 360 CORP & VUA HỆ THỐNG. All rights reserved.
//

#import "MacVietKeyManager.h"

extern void MacVietKeyInit(void);

extern CGEventRef MacVietKeyCallback(CGEventTapProxy proxy,
                                  CGEventType type,
                                  CGEventRef event,
                                  void *refcon);

extern NSString* ConvertUtil(NSString* str);

@interface MacVietKeyUpdater : NSObject <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSWindow *progressWindow;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSProgressIndicator *progressBar;
@property (nonatomic, strong) NSButton *cancelButton;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, copy) NSString *targetVersion;
@property (nonatomic, copy) NSString *releaseUrl;
@property (nonatomic, copy) NSString *dmgFallbackUrl;
@property (nonatomic, assign) BOOL didFallbackToDmg;
@property (nonatomic, assign) BOOL isCancelled;
@end

static MacVietKeyUpdater *_activeUpdater = nil;

@implementation MacVietKeyUpdater

+ (NSImage *)appIconImage {
    NSImage *appIcon = [NSImage imageNamed:@"Icon"];
    if (!appIcon) {
        NSString *iconPath = [[NSBundle mainBundle] pathForResource:@"Icon" ofType:@"icns"];
        if (iconPath) {
            appIcon = [[NSImage alloc] initWithContentsOfFile:iconPath];
        }
    }
    return appIcon;
}

- (void)startWithVersion:(NSString *)version zipUrl:(NSString *)zipUrl dmgUrl:(NSString *)dmgUrl releaseUrl:(NSString *)releaseUrl {
    self.targetVersion = version;
    self.dmgFallbackUrl = dmgUrl;
    self.releaseUrl = releaseUrl ?: @"https://github.com/360org/MacVietKey/releases/latest";
    self.didFallbackToDmg = NO;
    self.isCancelled = NO;

    [self showProgressWindow];
    [self beginDownloadFromURLString:zipUrl];
}

- (void)showProgressWindow {
    NSRect frame = NSMakeRect(0, 0, 420, 140);
    self.progressWindow = [[NSWindow alloc] initWithContentRect:frame
                                                      styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                                                        backing:NSBackingStoreBuffered
                                                          defer:NO];
    [self.progressWindow setTitle:[NSString stringWithFormat:@"Cập nhật MacVietKey v%@", self.targetVersion]];
    [self.progressWindow setLevel:NSFloatingWindowLevel];
    [self.progressWindow center];
    [self.progressWindow setReleasedWhenClosed:NO];

    NSView *content = self.progressWindow.contentView;

    NSImageView *iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(20, 62, 56, 56)];
    iconView.image = [MacVietKeyUpdater appIconImage];
    iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
    [content addSubview:iconView];

    self.statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(92, 92, 308, 22)];
    self.statusLabel.bezeled = NO;
    self.statusLabel.drawsBackground = NO;
    self.statusLabel.editable = NO;
    self.statusLabel.selectable = NO;
    self.statusLabel.font = [NSFont boldSystemFontOfSize:13];
    self.statusLabel.stringValue = [NSString stringWithFormat:@"Đang tải MacVietKey v%@...", self.targetVersion];
    [content addSubview:self.statusLabel];

    self.progressBar = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(92, 62, 308, 20)];
    self.progressBar.indeterminate = NO;
    self.progressBar.minValue = 0.0;
    self.progressBar.maxValue = 100.0;
    self.progressBar.doubleValue = 0.0;
    [content addSubview:self.progressBar];

    self.cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(310, 16, 90, 28)];
    [self.cancelButton setTitle:@"Huỷ"];
    [self.cancelButton setBezelStyle:NSBezelStyleRounded];
    [self.cancelButton setTarget:self];
    [self.cancelButton setAction:@selector(onCancel:)];
    [content addSubview:self.cancelButton];

    [NSApp activateIgnoringOtherApps:YES];
    [self.progressWindow makeKeyAndOrderFront:nil];
}

- (void)onCancel:(id)sender {
    self.isCancelled = YES;
    [self.downloadTask cancel];
    [self.session invalidateAndCancel];
    [self closeProgressWindow];
    _activeUpdater = nil;
}

- (void)closeProgressWindow {
    if (self.progressWindow) {
        [self.progressWindow orderOut:nil];
        [self.progressWindow close];
        self.progressWindow = nil;
    }
}

- (void)beginDownloadFromURLString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self handleFailureWithMessage:@"Đường dẫn tải bản cập nhật không hợp lệ."];
        return;
    }
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.timeoutIntervalForRequest = 30.0;
    config.timeoutIntervalForResource = 180.0;
    self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    self.downloadTask = [self.session downloadTaskWithRequest:req];
    [self.downloadTask resume];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (self.isCancelled) return;
    if (totalBytesExpectedToWrite > 0) {
        double pct = ((double)totalBytesWritten / (double)totalBytesExpectedToWrite) * 100.0;
        self.progressBar.indeterminate = NO;
        self.progressBar.doubleValue = pct;
        double mbDone = totalBytesWritten / (1024.0 * 1024.0);
        double mbTotal = totalBytesExpectedToWrite / (1024.0 * 1024.0);
        self.statusLabel.stringValue = [NSString stringWithFormat:@"Đang tải MacVietKey v%@ (%.1f / %.1f MB - %.0f%%)", self.targetVersion, mbDone, mbTotal, pct];
    } else {
        self.progressBar.indeterminate = YES;
        [self.progressBar startAnimation:nil];
        double mbDone = totalBytesWritten / (1024.0 * 1024.0);
        self.statusLabel.stringValue = [NSString stringWithFormat:@"Đang tải MacVietKey v%@ (%.1f MB)...", self.targetVersion, mbDone];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    if (self.isCancelled) return;

    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)downloadTask.response;
    NSInteger statusCode = [httpResp isKindOfClass:[NSHTTPURLResponse class]] ? httpResp.statusCode : 0;
    if (statusCode < 200 || statusCode >= 400) {
        if (!self.didFallbackToDmg && self.dmgFallbackUrl.length > 0) {
            self.didFallbackToDmg = YES;
            [self.session finishTasksAndInvalidate];
            [self beginDownloadFromURLString:self.dmgFallbackUrl];
            return;
        }
        [self handleFailureWithMessage:[NSString stringWithFormat:@"Máy chủ trả về mã lỗi HTTP %ld khi tải bản cập nhật.", (long)statusCode]];
        return;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *attrs = [fm attributesOfItemAtPath:location.path error:nil];
    unsigned long long fileSize = [attrs fileSize];
    if (fileSize < 100000) {
        [self handleFailureWithMessage:@"Tệp bản cập nhật tải về không đầy đủ hoặc bị lỗi."];
        return;
    }

    // Move downloaded file out of temporary URL before handler returns
    NSString *stagingDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"MacVietKeyUpdate_%d", getpid()]];
    [fm removeItemAtPath:stagingDir error:nil];
    [fm createDirectoryAtPath:stagingDir withIntermediateDirectories:YES attributes:nil error:nil];

    NSString *ext = self.didFallbackToDmg ? @"dmg" : @"zip";
    NSString *archivePath = [stagingDir stringByAppendingPathComponent:[NSString stringWithFormat:@"update.%@", ext]];
    NSError *moveErr = nil;
    if (![fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:archivePath] error:&moveErr]) {
        [self handleFailureWithMessage:@"Không thể lưu tệp bản cập nhật vào thư mục tạm."];
        return;
    }

    [self.session finishTasksAndInvalidate];
    self.cancelButton.enabled = NO;
    self.progressBar.indeterminate = YES;
    [self.progressBar startAnimation:nil];
    self.statusLabel.stringValue = @"Đang giải nén và cài đặt bản mới...";

    BOOL isDmg = self.didFallbackToDmg;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self extractAndInstallFromArchive:archivePath stagingDir:stagingDir isDmg:isDmg];
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (self.isCancelled || !error) return;
    [self handleFailureWithMessage:[NSString stringWithFormat:@"Lỗi tải bản cập nhật: %@", error.localizedDescription]];
}

- (void)extractAndInstallFromArchive:(NSString *)archivePath stagingDir:(NSString *)stagingDir isDmg:(BOOL)isDmg {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *extractDir = [stagingDir stringByAppendingPathComponent:@"extract"];
    [fm createDirectoryAtPath:extractDir withIntermediateDirectories:YES attributes:nil error:nil];

    NSString *extractedApp = nil;

    if (!isDmg) {
        NSTask *dittoTask = [[NSTask alloc] init];
        dittoTask.launchPath = @"/usr/bin/ditto";
        dittoTask.arguments = @[@"-xk", archivePath, extractDir];
        [dittoTask launch];
        [dittoTask waitUntilExit];
        if (dittoTask.terminationStatus != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleFailureWithMessage:@"Giải nén gói cập nhật ZIP thất bại."];
            });
            return;
        }
        extractedApp = [extractDir stringByAppendingPathComponent:@"MacVietKey.app"];
    } else {
        NSString *mountPoint = [stagingDir stringByAppendingPathComponent:@"mnt"];
        [fm createDirectoryAtPath:mountPoint withIntermediateDirectories:YES attributes:nil error:nil];

        NSTask *attachTask = [[NSTask alloc] init];
        attachTask.launchPath = @"/usr/bin/hdiutil";
        attachTask.arguments = @[@"attach", archivePath, @"-nobrowse", @"-readonly", @"-mountpoint", mountPoint];
        [attachTask launch];
        [attachTask waitUntilExit];

        if (attachTask.terminationStatus == 0) {
            NSString *mountedApp = [mountPoint stringByAppendingPathComponent:@"MacVietKey.app"];
            if ([fm fileExistsAtPath:mountedApp]) {
                extractedApp = [extractDir stringByAppendingPathComponent:@"MacVietKey.app"];
                NSTask *copyTask = [[NSTask alloc] init];
                copyTask.launchPath = @"/usr/bin/ditto";
                copyTask.arguments = @[mountedApp, extractedApp];
                [copyTask launch];
                [copyTask waitUntilExit];
            }
            NSTask *detachTask = [[NSTask alloc] init];
            detachTask.launchPath = @"/usr/bin/hdiutil";
            detachTask.arguments = @[@"detach", mountPoint, @"-force"];
            [detachTask launch];
            [detachTask waitUntilExit];
        }
    }

    NSString *execPath = [extractedApp stringByAppendingPathComponent:@"Contents/MacOS/MacVietKey"];
    if (!extractedApp || ![fm isExecutableFileAtPath:execPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleFailureWithMessage:@"Không tìm thấy tệp thực thi MacVietKey.app hợp lệ trong gói cập nhật."];
        });
        return;
    }

    // Clear quarantine attributes before verifying/installing
    NSTask *xattrTask = [[NSTask alloc] init];
    xattrTask.launchPath = @"/usr/bin/xattr";
    xattrTask.arguments = @[@"-cr", extractedApp];
    [xattrTask launch];
    [xattrTask waitUntilExit];

    // Verify code signature integrity
    NSTask *verifyTask = [[NSTask alloc] init];
    verifyTask.launchPath = @"/usr/bin/codesign";
    verifyTask.arguments = @[@"--verify", @"--deep", @"--strict", extractedApp];
    [verifyTask launch];
    [verifyTask waitUntilExit];
    if (verifyTask.terminationStatus != 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleFailureWithMessage:@"Chữ ký số của gói cập nhật không hợp lệ. Hủy cài đặt để bảo vệ hệ thống."];
        });
        return;
    }

    // Determine target install path
    NSString *currentBundle = [[NSBundle mainBundle] bundlePath];
    NSString *targetApp = @"/Applications/MacVietKey.app";
    if ([currentBundle hasSuffix:@".app"] &&
        ![currentBundle hasPrefix:@"/Volumes/"] &&
        ![currentBundle containsString:@"/AppTranslocation/"]) {
        targetApp = currentBundle;
    }

    NSString *targetParent = [targetApp stringByDeletingLastPathComponent];
    BOOL canWriteDirect = [fm isWritableFileAtPath:targetParent] &&
                          (![fm fileExistsAtPath:targetApp] || [fm isWritableFileAtPath:targetApp]);

    if (!canWriteDirect) {
        // Request admin authorization cleanly via AppleScript for locked /Applications
        NSString *shellCmd = [NSString stringWithFormat:
            @"rm -rf '%@.bak' && (test ! -e '%@' || mv '%@' '%@.bak') && mv '%@' '%@' && rm -rf '%@.bak' && xattr -cr '%@'",
            targetApp, targetApp, targetApp, targetApp, extractedApp, targetApp, targetApp, targetApp];
        NSString *escapedCmd = [shellCmd stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
        escapedCmd = [escapedCmd stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString *appleScript = [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", escapedCmd];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *errDict = nil;
            NSAppleScript *script = [[NSAppleScript alloc] initWithSource:appleScript];
            NSAppleEventDescriptor *res = [script executeAndReturnError:&errDict];
            if (!res) {
                [self handleFailureWithMessage:@"Không có quyền ghi vào thư mục Applications để hoàn tất cập nhật."];
                return;
            }
            [[NSUserDefaults standardUserDefaults] setObject:self.targetVersion forKey:@"JustUpdatedToVersion"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self relaunchAppAfterExit:targetApp stagingDir:stagingDir alreadyReplaced:YES];
        });
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults] setObject:self.targetVersion forKey:@"JustUpdatedToVersion"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self relaunchAppAfterExit:targetApp stagingDir:stagingDir alreadyReplaced:NO extractedApp:extractedApp];
    });
}

- (void)relaunchAppAfterExit:(NSString *)targetApp stagingDir:(NSString *)stagingDir alreadyReplaced:(BOOL)alreadyReplaced {
    [self relaunchAppAfterExit:targetApp stagingDir:stagingDir alreadyReplaced:alreadyReplaced extractedApp:nil];
}

- (void)relaunchAppAfterExit:(NSString *)targetApp stagingDir:(NSString *)stagingDir alreadyReplaced:(BOOL)alreadyReplaced extractedApp:(NSString *)extractedApp {
    pid_t pid = [[NSProcessInfo processInfo] processIdentifier];
    NSString *scriptPath = [stagingDir stringByAppendingPathComponent:@"install.sh"];
    NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/MacVietKeyUpdate.log"];

    NSString *scriptBody = nil;
    if (alreadyReplaced) {
        scriptBody = [NSString stringWithFormat:
            @"#!/bin/sh\n"
            "exec > '%@' 2>&1\n"
            "i=0\n"
            "while kill -0 %d 2>/dev/null && [ $i -lt 30 ]; do sleep 0.2; i=$((i+1)); done\n"
            "kill -9 %d 2>/dev/null || true\n"
            "sleep 0.3\n"
            "/usr/bin/xattr -cr '%@' 2>/dev/null || true\n"
            "/usr/bin/open -n '%@'\n"
            "rm -rf '%@' 2>/dev/null || true\n",
            logPath, pid, pid, targetApp, targetApp, stagingDir];
    } else {
        scriptBody = [NSString stringWithFormat:
            @"#!/bin/sh\n"
            "exec > '%@' 2>&1\n"
            "echo \"[MacVietKeyUpdate] Waiting for PID %d to exit...\"\n"
            "i=0\n"
            "while kill -0 %d 2>/dev/null && [ $i -lt 30 ]; do sleep 0.2; i=$((i+1)); done\n"
            "kill -9 %d 2>/dev/null || true\n"
            "sleep 0.3\n"
            "BACKUP='%@.bak.%d'\n"
            "rm -rf \"$BACKUP\"\n"
            "if [ -e '%@' ]; then\n"
            "  mv '%@' \"$BACKUP\" || exit 1\n"
            "fi\n"
            "if mv '%@' '%@'; then\n"
            "  rm -rf \"$BACKUP\"\n"
            "  /usr/bin/xattr -cr '%@' 2>/dev/null || true\n"
            "  echo \"[MacVietKeyUpdate] Installed successfully. Relaunching...\"\n"
            "  /usr/bin/open -n '%@'\n"
            "else\n"
            "  echo \"[MacVietKeyUpdate] Swap failed, rolling back...\"\n"
            "  if [ -e \"$BACKUP\" ]; then mv \"$BACKUP\" '%@'; fi\n"
            "  /usr/bin/open -n '%@'\n"
            "fi\n"
            "rm -rf '%@' 2>/dev/null || true\n",
            logPath, pid, pid, pid, targetApp, pid, targetApp, targetApp, extractedApp, targetApp, targetApp, targetApp, targetApp, targetApp, stagingDir];
    }

    NSError *writeErr = nil;
    [scriptBody writeToFile:scriptPath atomically:YES encoding:NSUTF8StringEncoding error:&writeErr];
    if (writeErr) {
        [self handleFailureWithMessage:@"Không thể tạo tiến trình cài đặt tự động."];
        return;
    }

    NSTask *chmodTask = [[NSTask alloc] init];
    chmodTask.launchPath = @"/bin/chmod";
    chmodTask.arguments = @[@"+x", scriptPath];
    [chmodTask launch];
    [chmodTask waitUntilExit];

    // Spawn detached updater script so it survives [NSApp terminate]
    NSTask *updaterTask = [[NSTask alloc] init];
    updaterTask.launchPath = @"/bin/sh";
    updaterTask.arguments = @[@"-c", [NSString stringWithFormat:@"nohup /bin/sh '%@' >/dev/null 2>&1 &", scriptPath]];
    [updaterTask launch];
    [updaterTask waitUntilExit];

    [self closeProgressWindow];
    _activeUpdater = nil;
    [NSApp terminate:nil];
}

- (void)handleFailureWithMessage:(NSString *)msg {
    [self closeProgressWindow];
    _activeUpdater = nil;

    NSAlert *errAlert = [[NSAlert alloc] init];
    NSImage *appIcon = [MacVietKeyUpdater appIconImage];
    if (appIcon) [errAlert setIcon:appIcon];
    [errAlert setMessageText:@"Không thể tự động cập nhật MacVietKey"];
    [errAlert setInformativeText:msg];
    [errAlert addButtonWithTitle:@"Mở trang tải về"];
    [errAlert addButtonWithTitle:@"Đóng"];
    [errAlert.window setLevel:NSStatusWindowLevel];
    [NSApp activateIgnoringOtherApps:YES];

    if ([errAlert runModal] == NSAlertFirstButtonReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.releaseUrl]];
    }
}

@end

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
    NSImage *appIcon = [MacVietKeyUpdater appIconImage];
    if (appIcon) [alert setIcon:appIcon];
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
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:config];
    NSURL *url = [NSURL URLWithString:@"https://raw.githubusercontent.com/360org/MacVietKey/master/version.json"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15.0];

    [[aSession dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        if (!error && [httpResp isKindOfClass:[NSHTTPURLResponse class]] && httpResp.statusCode == 200 && data) {
            NSError *jsonError = nil;
            id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (!jsonError && [object isKindOfClass:[NSDictionary class]]) {
                NSDictionary *results = (NSDictionary *)object;
                NSDictionary *ver = [results valueForKey:@"latestVersion"];
                if ([ver isKindOfClass:[NSDictionary class]]) {
                    int versionCode = [[ver valueForKey:@"versionCode"] intValue];
                    NSString *versionName = [ver valueForKey:@"versionName"];
                    NSString *zipUrl = [ver valueForKey:@"downloadZipUrl"];
                    NSString *dmgUrl = [ver valueForKey:@"downloadUrl"];
                    NSString *releaseUrl = [ver valueForKey:@"releaseUrl"];
                    if (!zipUrl || zipUrl.length == 0) {
                        zipUrl = [NSString stringWithFormat:@"https://github.com/360org/MacVietKey/releases/download/v%@/MacVietKey-v%@-macOS.zip", versionName, versionName];
                    }
                    if (!dmgUrl || dmgUrl.length == 0) {
                        dmgUrl = [NSString stringWithFormat:@"https://github.com/360org/MacVietKey/releases/download/v%@/MacVietKey-v%@-macOS.dmg", versionName, versionName];
                    }
                    int currentVersionCode = [((NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]) intValue];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callback != nil) {
                            callback();
                        }
                        if (versionCode > currentVersionCode || callback != nil) {
                            [self showUpdateMessage:parent
                                       needUpdating:(versionCode > currentVersionCode)
                                         newVersion:versionName
                                             zipUrl:zipUrl
                                             dmgUrl:dmgUrl
                                         releaseUrl:releaseUrl];
                        }
                    });
                    return;
                }
            }
        }
        // Ensure callback is always restored even on network failure
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback != nil) {
                callback();
                [self showMessage:parent
                          message:@"Không thể kiểm tra phiên bản mới"
                           subMsg:@"Vui lòng kiểm tra kết nối mạng và thử lại."];
            }
        });
    }] resume];
}

+(void)showUpdateMessage:(NSWindow*)parent needUpdating:(BOOL)needUpdating newVersion:(NSString*)versionString {
    NSString *zipUrl = [NSString stringWithFormat:@"https://github.com/360org/MacVietKey/releases/download/v%@/MacVietKey-v%@-macOS.zip", versionString, versionString];
    NSString *dmgUrl = [NSString stringWithFormat:@"https://github.com/360org/MacVietKey/releases/download/v%@/MacVietKey-v%@-macOS.dmg", versionString, versionString];
    [self showUpdateMessage:parent needUpdating:needUpdating newVersion:versionString zipUrl:zipUrl dmgUrl:dmgUrl releaseUrl:@"https://github.com/360org/MacVietKey/releases/latest"];
}

+(void)showUpdateMessage:(NSWindow*)parent needUpdating:(BOOL)needUpdating newVersion:(NSString*)versionString zipUrl:(NSString*)zipUrl dmgUrl:(NSString*)dmgUrl releaseUrl:(NSString*)releaseUrl {
    NSAlert *alert = [[NSAlert alloc] init];
    NSImage *appIcon = [MacVietKeyUpdater appIconImage];
    if (appIcon) {
        [alert setIcon:appIcon];
    }
    [alert setMessageText:(needUpdating ? [NSString stringWithFormat:@"MacVietKey có phiên bản mới (%@), bạn có muốn cập nhật không?", versionString] : @"Bạn đang dùng phiên bản mới nhất!")];
    [alert setInformativeText:(needUpdating ? @"Bấm 'Có' để tự động tải về, cài đặt và khởi động lại MacVietKey." : @"")];

    if (!needUpdating) {
        [alert addButtonWithTitle:@"OK"];
    } else {
        [alert addButtonWithTitle:@"Có"];
        [alert addButtonWithTitle:@"Không"];
    }

    if (parent == nil) {
        [NSApp activateIgnoringOtherApps:YES];
        [alert.window makeKeyAndOrderFront:nil];
        [alert.window setLevel:NSStatusWindowLevel];
        NSModalResponse res = [alert runModal];
        if (res == NSAlertFirstButtonReturn && needUpdating) {
            [self downloadAndInstallUpdate:versionString zipUrl:zipUrl dmgUrl:dmgUrl releaseUrl:releaseUrl];
        }
    } else {
        [alert beginSheetModalForWindow:parent completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn && needUpdating) {
                [self downloadAndInstallUpdate:versionString zipUrl:zipUrl dmgUrl:dmgUrl releaseUrl:releaseUrl];
            }
        }];
    }
}

+(void)downloadAndInstallUpdate:(NSString*)versionString {
    NSString *zipUrl = [NSString stringWithFormat:@"https://github.com/360org/MacVietKey/releases/download/v%@/MacVietKey-v%@-macOS.zip", versionString, versionString];
    NSString *dmgUrl = [NSString stringWithFormat:@"https://github.com/360org/MacVietKey/releases/download/v%@/MacVietKey-v%@-macOS.dmg", versionString, versionString];
    [self downloadAndInstallUpdate:versionString zipUrl:zipUrl dmgUrl:dmgUrl releaseUrl:@"https://github.com/360org/MacVietKey/releases/latest"];
}

+(void)downloadAndInstallUpdate:(NSString*)versionString zipUrl:(NSString*)zipUrl dmgUrl:(NSString*)dmgUrl releaseUrl:(NSString*)releaseUrl {
    if (_activeUpdater != nil) {
        [NSApp activateIgnoringOtherApps:YES];
        [_activeUpdater.progressWindow makeKeyAndOrderFront:nil];
        return;
    }
    _activeUpdater = [[MacVietKeyUpdater alloc] init];
    [_activeUpdater startWithVersion:versionString zipUrl:zipUrl dmgUrl:dmgUrl releaseUrl:releaseUrl];
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
