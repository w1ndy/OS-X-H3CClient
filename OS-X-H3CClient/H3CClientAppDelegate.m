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
    self.backend = [[H3CClientBackend alloc] init];
    [self.backend addObserver:self forKeyPath:@"connectionState" options:NSKeyValueObservingOptionNew context:nil];
    
    self.menuViewController = [[StatusMenuViewController alloc] initWithBackend:self.backend];
    self.menuViewController.delegate = self;
    
    if([(NSArray *)[self.backend.globalConfiguration objectForKey:@"profiles"] count] == 0) {
        [self.backend.globalConfiguration setInteger:-1 forKey:@"default"];
    }
    if([self.backend.globalConfiguration boolForKey:@"autoconnect"]) {
        [self.backend connect];
    }
    
    self.applicationDescView.stringValue = [NSString stringWithFormat:@"H3CClientX v%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    
    self.stderrPipe = [NSPipe pipe];
    self.stderrPipeReadHandle = [self.stderrPipe fileHandleForReading];
    dup2([[self.stderrPipe fileHandleForWriting] fileDescriptor], fileno(stderr));
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleStderrNotification:) name: NSFileHandleReadCompletionNotification object: self.stderrPipeReadHandle];
    [self.stderrPipeReadHandle readInBackgroundAndNotify];
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
    switch (self.backend.connectionState) {
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
    self.usernameStatus.stringValue = [self.backend getUserName];
    self.ipaddrStatus.stringValue = [self.backend getIPAddress];
}

- (void)updateConnectedTime:(id)timer
{
    NSLog(@"updating timer");
    if(!self.window.visible) {
        [timer stop:timer];
        return ;
    }
    if(self.backend.connectionState == Connected) {
        long d = time(NULL) - self.backend.timeConnected;
        self.durationStatus.stringValue = [NSString stringWithFormat:@"%02ld:%02ld:%02ld:%02ld",(long)(d / 86400),(long)(d / 3600 % 24),(long)(d / 60 % 60),(long)(d % 60)];
    }
}

- (void)showPreferences
{
    BOOL isAutoConnect = [self.backend.globalConfiguration boolForKey:@"autoconnect"];
    
    [self updateStatusPane];
    [NSTimer timerWithTimeInterval:1 target:self selector:@selector(updateConnectedTime:) userInfo:nil repeats:YES];
    if([self.backend.globalConfiguration boolForKey:@"reconnect"])
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
        [self.backend.globalConfiguration setBool:YES forKey:@"autoconnect"];
    } else {
        [self.backend.globalConfiguration setBool:NO forKey:@"autoconnect"];
    }
}
- (IBAction)toggleReconnect:(id)sender {
    if([self.reconnectView state] == NSOnState) {
        [self.backend.globalConfiguration setBool:YES forKey:@"reconnect"];
    } else {
        [self.backend.globalConfiguration setBool:NO forKey:@"reconnect"];
    }
}


@end
