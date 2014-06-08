//
//  H3CClientAppDelegate.m
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import "H3CClientAppDelegate.h"
#import "H3CClientProfileStorage.h"

@implementation H3CClientAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.willReconnect = NO;
    
    [self.progressView stopAnimation:nil];
    [self.applyView setEnabled:YES];
    
    self.backend = [[H3CClientBackend alloc] init];
    [self.backend addObserver:self forKeyPath:@"connectionState" options:NSKeyValueObservingOptionNew context:nil];
    
    self.menuViewController = [[StatusMenuViewController alloc] initWithBackend:self.backend];
    self.menuViewController.delegate = self;
    
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
    [self animatePreferencesWindowWithView:self.generalView];
    self.toolbarView.selectedItemIdentifier = @"General";
    NSLog(@"tab switch");
}
- (IBAction)onPreferencesAccounts:(id)sender
{
    [self animatePreferencesWindowWithView:self.accountsView];
    self.toolbarView.selectedItemIdentifier = @"Accounts";
    NSLog(@"tab switch");
}

- (IBAction)onPreferencesAdvanced:(id)sender {
    [self animatePreferencesWindowWithView:self.advancedView];
    self.toolbarView.selectedItemIdentifier = @"Advanced";
    [self.logView scrollToEndOfDocument:self];
    NSLog(@"tab switch");
}

- (IBAction)onPreferencesAbout:(id)sender
{
    [self animatePreferencesWindowWithView:self.aboutView];
    self.toolbarView.selectedItemIdentifier = @"About";
    NSLog(@"tab switch");
}

- (void)animatePreferencesWindowWithView:(NSView *)view
{
    NSWindow *window = self.window;
    CGSize size = view.frame.size;
    NSRect windowFrame = [window contentRectForFrameRect:window.frame];
    NSRect newWindowFrame = [window frameRectForContentRect:
                             NSMakeRect( NSMinX( windowFrame ), NSMaxY( windowFrame ) - size.height, size.width, size.height )];
    window.contentView = view;
    [window setFrame:newWindowFrame display:YES animate:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"connectionState"]) {
        enum ConnectionState newState;
        [(NSValue *)[change objectForKey:@"new"] getValue:&newState];
        switch(newState) {
            case Disconnected:
                [self.progressView stopAnimation:nil];
                [self.applyView setEnabled:YES];
                if(self.willReconnect) {
                    self.willReconnect = NO;
                   [self.backend connect];
                }
                break;
            case Connected:
                [self.progressView stopAnimation:nil];
                [self.applyView setEnabled:YES];
                break;
            case Connecting:
                [self.progressView startAnimation:nil];
                [self.applyView setEnabled:NO];
                break;
            case Disconnecting:
                [self.progressView startAnimation:nil];
                [self.applyView setEnabled:NO];
                break;
        }
    }
}

- (void)showPreferences
{
    NSString *username = [self.backend.globalConfiguration stringForKey:@"userName"];
    NSString *password = [self.backend.globalConfiguration stringForKey:@"password"];
    NSString *last_interface = [self.backend.globalConfiguration stringForKey:@"lastUsedInterface"];
    BOOL isAutoConnect = [self.backend.globalConfiguration boolForKey:@"autoconnect"];
    
    if(username)
        [self.usernameView setStringValue:username];
    else
        [self.usernameView setStringValue:@""];
    
    if(password)
        [self.passwordView setStringValue:password];
    else
        [self.passwordView setStringValue:@""];
    
    if(isAutoConnect)
        self.autoconnectView.state = NSOnState;
    else
        self.autoconnectView.state = NSOffState;
    
    [self.interfaceView removeAllItems];
    if([self.backend.adapterList count]) {
        [self.interfaceView addItemsWithTitles:[[self.backend.adapterList allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
        if(last_interface == nil) {
            [self.interfaceView selectItemAtIndex:0];
            [self.backend.globalConfiguration setObject:self.backend.adapterList[[self.interfaceView titleOfSelectedItem]] forKey:@"lastUsedInterface"];
        } else {
            BOOL found = false;
            for(id key in [self.backend.adapterList allKeys]) {
                if([self.backend.adapterList[key] isEqual:last_interface]) {
                    [self.interfaceView selectItemWithTitle:key];
                    found = true;
                    break;
                }
            }
            if(!found)
                [self.interfaceView selectItemAtIndex:0];
        }
    } else {
        [self.interfaceView setEnabled:NO];
        [self.applyView setEnabled:NO];
        [self.interfaceView addItemWithTitle:@"No interface found"];
        [self.interfaceView selectItemAtIndex:0];
    }
    
    [self animatePreferencesWindowWithView:self.generalView];
    self.toolbarView.selectedItemIdentifier = @"General";
    [self.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    if(self.backend.connectionState == Connecting || self.backend.connectionState == Disconnecting) {
        [self.progressView startAnimation:self];
    }
}

- (IBAction)onPreferencesApply:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    if([[self.usernameView stringValue] isEqualToString:@""]) {
        [alert setMessageText:@"Username is required."];
        [alert setIcon:[NSImage imageNamed:NSImageNameInfo]];
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse resp){}];
        return ;
    }
    
    if([[self.passwordView stringValue] isEqualToString:@""]) {
        [alert setMessageText:@"Password is required."];
        [alert setIcon:[NSImage imageNamed:NSImageNameInfo]];
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse resp){}];
        return ;
    }
    
    [self.backend.globalConfiguration setObject:[self.usernameView stringValue] forKey:@"userName"];
    [self.backend.globalConfiguration setObject:[self.passwordView stringValue] forKey:@"password"];
    [self.backend.globalConfiguration setObject:self.backend.adapterList[[self.interfaceView titleOfSelectedItem]] forKey:@"lastUsedInterface"];
    
    if(self.backend.connectionState == Disconnected) {
        [self.backend connect];
    } else {
        self.willReconnect = YES;
        [self.backend disconnect];
    }
}

- (IBAction)toggleAutoConnect:(id)sender {
    NSButton *checkbox = sender;
    if([checkbox state] == NSOnState) {
        [self.backend.globalConfiguration setBool:YES forKey:@"autoconnect"];
    } else {
        [self.backend.globalConfiguration setBool:NO forKey:@"autoconnect"];
    }
}

- (IBAction)onSelectProfile:(id)sender
{
}

@end
