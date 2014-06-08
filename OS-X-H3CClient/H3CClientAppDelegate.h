//
//  H3CClientAppDelegate.h
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

#import "H3CClientBackend.h"
#import "StatusMenuViewController.h"

@interface H3CClientAppDelegate : NSObject <NSApplicationDelegate, StatusMenuViewControllerDelegate>

@property (nonatomic, weak) IBOutlet NSWindow *window;
@property (nonatomic) H3CClientBackend *backend;
@property (nonatomic) StatusMenuViewController *menuViewController;
@property (nonatomic) BOOL willReconnect;

@property (nonatomic) NSPipe *stdoutPipe;
@property (nonatomic) NSFileHandle *stdoutPipeReadHandle;
@property (nonatomic) NSPipe *stderrPipe;
@property (nonatomic) NSFileHandle *stderrPipeReadHandle;

@property (nonatomic, weak) IBOutlet NSTextField *usernameView;
@property (nonatomic, weak) IBOutlet NSSecureTextField *passwordView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *interfaceView;
@property (nonatomic, weak) IBOutlet NSButton *applyView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressView;
@property (nonatomic, weak) IBOutlet NSButton *autoconnectView;
@property (nonatomic, weak) IBOutlet NSToolbar *toolbarView;

@property (nonatomic, weak) IBOutlet NSView *generalView;
@property (nonatomic, weak) IBOutlet NSView *advancedView;
@property (nonatomic, weak) IBOutlet NSView *aboutView;
@property (nonatomic, weak) IBOutlet NSView *accountsView;

@property (nonatomic, weak) IBOutlet SUUpdater *updaterView;
@property (nonatomic, weak) IBOutlet NSTextField *applicationDescView;
@property (nonatomic) IBOutlet NSTextView *logView;
//@property (weak) IBOutlet NSScrollView *profilesView;
@property (weak) IBOutlet NSTableView *profilesView;

@end
