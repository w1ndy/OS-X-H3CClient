//
//  H3CClientAppDelegate.m
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import "H3CClientAppDelegate.h"

@implementation H3CClientAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self chmodBPF];

    self.timer = nil;
    [[H3CClientBackend defaultBackend] addObserver:self forKeyPath:@"connectionState" options:NSKeyValueObservingOptionNew context:nil];

    self.menuViewController = [[StatusMenuViewController alloc] init];
    self.menuViewController.delegate = self;

    if([(NSArray *)[[H3CClientBackend defaultBackend].globalConfiguration objectForKey:@"profiles"] count] == 0) {
        [[H3CClientBackend defaultBackend].globalConfiguration setInteger:-1 forKey:@"default"];
    }
    if([[H3CClientBackend defaultBackend].globalConfiguration boolForKey:@"autoconnect"]) {
        [[H3CClientBackend defaultBackend] connect];
    }

    self.applicationDescView.stringValue = [NSString stringWithFormat:@"H3CClientX v%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];

    self.stderrPipe = [NSPipe pipe];
    self.stderrPipeReadHandle = [self.stderrPipe fileHandleForReading];
    dup2([[self.stderrPipe fileHandleForWriting] fileDescriptor], fileno(stderr));

    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleStderrNotification:) name: NSFileHandleReadCompletionNotification object: self.stderrPipeReadHandle];
    [self.stderrPipeReadHandle readInBackgroundAndNotify];
}

- (void)chmodBPF
{
    if([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/LaunchDaemons/org.wireshark.ChmodBPF.plist"]) {
        NSLog(@"BPF helper detected.");
        return ;
    }
    NSDictionary *err = [NSDictionary new];
    NSString *script = [NSString stringWithFormat:@"do shell script \"chgrp admin /dev/bpf* && chmod g+rw /dev/bpf* && cp %@ /Library/LaunchDaemons\" with administrator privileges", [[NSBundle mainBundle] pathForResource:@"org.wireshark.ChmodBPF.plist" ofType:nil]];
    NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
    NSAppleEventDescriptor *evtDesc = [appleScript executeAndReturnError:&err];

    if(!evtDesc) {
        [[NSAlert alertWithMessageText:@"Error" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"Failed to install BPF helper."] runModal];
    } else {
        NSLog(@"BPF helper installed successfully.");
    }
}

- (void)handleStderrNotification:(id)notification
{
    [self.stderrPipeReadHandle readInBackgroundAndNotify];
    NSString *str = [[NSString alloc] initWithData: [[notification userInfo] objectForKey: NSFileHandleNotificationDataItem] encoding: NSUTF8StringEncoding];
    self.logView.string = [self.logView.string stringByAppendingString:str];
    printf("%s", [str UTF8String]);
}

- (IBAction)onPreferencesGeneral:(id)sender
{
    if(self.window.contentView == self.generalView) return ;
    [self animatePreferencesWindowWithView:self.generalView];
}
- (IBAction)onPreferencesAccounts:(id)sender
{
    if(self.window.contentView == self.accountsView) return ;
    [self animatePreferencesWindowWithView:self.accountsView];
}

- (IBAction)onPreferencesAdvanced:(id)sender
{
    if(self.window.contentView == self.advancedView) return ;
    [self animatePreferencesWindowWithView:self.advancedView];
    [self.logView scrollToEndOfDocument:self];
}

- (IBAction)onPreferencesAbout:(id)sender
{
    if(self.window.contentView == self.aboutView) return ;
    [self animatePreferencesWindowWithView:self.aboutView];
}

- (void)animatePreferencesWindowWithView:(NSView *)view
{
    NSWindow *window = self.window;
    CGSize size = view.frame.size;
    NSRect windowFrame = [window contentRectForFrameRect:window.frame];
    NSRect newWindowFrame = [window frameRectForContentRect:
                             NSMakeRect( NSMinX( windowFrame ), NSMaxY( windowFrame ) - size.height, size.width, size.height )];
    //((NSView *)window.contentView).wantsLayer = YES;
    ((NSView *)window.contentView).animator.alphaValue = 0;
    view.wantsLayer = YES;
    view.alphaValue = 0;
    window.contentView = view;
    view.animator.alphaValue = 1;
    [window setFrame:newWindowFrame display:YES animate:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"connectionState"]) {
        [self updateStatusPane];
    }
}

- (void)updateStatusPane
{
    switch ([H3CClientBackend defaultBackend].connectionState) {
        case Disconnected:
            self.connectedStatus.stringValue = @"No";
            break;
        case Connected:
            self.connectedStatus.stringValue = @"Yes";
            break;
        case Disconnecting:
            self.connectedStatus.stringValue = @"Disconnecting";
            break;
        case Connecting:
            self.connectedStatus.stringValue = @"Connecting";
    }
    NSLog(@"Retrieving user name...");
    self.usernameStatus.stringValue = [[H3CClientBackend defaultBackend] getUserName];
    NSLog(@"User name retrieved.");
    NSLog(@"Retrieving IP address...");
    self.ipaddrStatus.stringValue = [[H3CClientBackend defaultBackend] getIPAddress];
    NSLog(@"IP Address retrieved.");
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if(self.timer != nil) return ;
    self.timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateConnectedTime:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    NSLog(@"Preference panel become active.");
}

- (void)applicationDidResignActive:(NSNotification *)notification
{
    if(self.timer == nil) return ;
    [self.timer invalidate];
    self.timer = nil;
    NSLog(@"Preference panel become inactive.");
}

- (void)updateConnectedTime:(id)timer
{
    if([H3CClientBackend defaultBackend].connectionState == Connected) {
        long d = time(NULL) - [H3CClientBackend defaultBackend].timeConnected;
        self.durationStatus.stringValue = [NSString stringWithFormat:@"%ld d %ld h %ld m %ld s",(long)(d / 86400),(long)(d / 3600 % 24),(long)(d / 60 % 60),(long)(d % 60)];
    }
    NSDictionary *stat = [[H3CClientBackend defaultBackend] getTrafficStatSinceConnected];
    self.trafficStatus.stringValue = [NSString stringWithFormat:@"%.1f MB / %.1f MB", ([(NSNumber*)stat[@"input"] floatValue] / 1024. / 1024.), ([(NSNumber *)stat[@"output"] floatValue] / 1024. / 1024.)];
}

- (void)showPreferences
{
    BOOL isAutoConnect = [[H3CClientBackend defaultBackend].globalConfiguration boolForKey:@"autoconnect"];

    [self updateStatusPane];
    if([[H3CClientBackend defaultBackend].globalConfiguration boolForKey:@"reconnect"])
        self.reconnectView.state = NSOnState;
    else
        self.reconnectView.state = NSOffState;

    if(isAutoConnect)
        self.autoconnectView.state = NSOnState;
    else
        self.autoconnectView.state = NSOffState;

    [self animatePreferencesWindowWithView:self.generalView];
    self.toolbarView.selectedItemIdentifier = @"General";
    [self.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)toggleAutoConnect:(id)sender {
    if([self.autoconnectView state] == NSOnState) {
        [[H3CClientBackend defaultBackend].globalConfiguration setBool:YES forKey:@"autoconnect"];
    } else {
        [[H3CClientBackend defaultBackend].globalConfiguration setBool:NO forKey:@"autoconnect"];
    }
}
- (IBAction)toggleReconnect:(id)sender {
    if([self.reconnectView state] == NSOnState) {
        [[H3CClientBackend defaultBackend].globalConfiguration setBool:YES forKey:@"reconnect"];
    } else {
        [[H3CClientBackend defaultBackend].globalConfiguration setBool:NO forKey:@"reconnect"];
    }
}
- (IBAction)visitSite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://w1ndy.github.io/OS-X-H3CClient/"]];
}

- (IBAction)resetAllAdapters:(id)sender
{
    NSMutableString *command = [[NSMutableString alloc] init];
    NSLog(@"%@",[H3CClientBackend defaultBackend].adapterList.allValues);
    for(NSString *adapter in [H3CClientBackend defaultBackend].adapterList.allValues) {
        if(command.length == 0) {
            [command appendFormat:@"ifconfig %@ down && ifconfig %@ up", adapter, adapter];
        } else {
            [command appendFormat:@" && ifconfig %@ down && ifconfig %@ up", adapter, adapter];
        }
    }
    if(command.length == 0) {
        [[NSAlert alertWithMessageText:@"Error" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"No adapter found."] beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse resp){}];
        return ;
    }
    NSDictionary *err = [NSDictionary new];
    NSString *script = [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", command];
    NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
    NSAppleEventDescriptor *evtDesc = [appleScript executeAndReturnError:&err];

    if(!evtDesc) {
        [[NSAlert alertWithMessageText:@"Error" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"Failed to reset adapters."] beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse resp) {}];
    } else {
        [[NSAlert alertWithMessageText:@"Info" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"All adapters have been reset."] beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse resp) {}];
    }
}

- (IBAction)refreshIPAddress:(id)sender
{
    [[H3CClientBackend defaultBackend] updateIP];
    [self updateStatusPane];
    [[NSAlert alertWithMessageText:@"Info" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"IP successfully refreshed."] beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse resp){
        return ;
    }];
    return ;
}
@end
