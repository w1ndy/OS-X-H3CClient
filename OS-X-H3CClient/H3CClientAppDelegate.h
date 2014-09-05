//
//  H3CClientAppDelegate.h
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "H3CClientBackend.h"
#import "StatusMenuViewController.h"

@interface H3CClientAppDelegate : NSObject <NSApplicationDelegate, StatusMenuViewControllerDelegate>

@property (nonatomic, weak) IBOutlet NSWindow *window;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) StatusMenuViewController *menuViewController;

@property (nonatomic) NSPipe *stdoutPipe;
@property (nonatomic) NSFileHandle *stdoutPipeReadHandle;
@property (nonatomic) NSPipe *stderrPipe;
@property (nonatomic) NSFileHandle *stderrPipeReadHandle;

@property (nonatomic, weak) IBOutlet NSButton *autoconnectView;
@property (nonatomic, weak) IBOutlet NSButton *reconnectView;
@property (nonatomic, weak) IBOutlet NSToolbar *toolbarView;

@property (nonatomic, weak) IBOutlet NSTextField *connectedStatus;
@property (nonatomic, weak) IBOutlet NSTextField *usernameStatus;
@property (nonatomic, weak) IBOutlet NSTextField *ipaddrStatus;
@property (nonatomic, weak) IBOutlet NSTextField *durationStatus;
@property (nonatomic, weak) IBOutlet NSTextField *trafficStatus;

@property (nonatomic, weak) IBOutlet NSView *generalView;
@property (nonatomic, weak) IBOutlet NSView *advancedView;
@property (nonatomic, weak) IBOutlet NSView *aboutView;
@property (nonatomic, weak) IBOutlet NSView *accountsView;

@property (nonatomic, weak) IBOutlet NSTextField *applicationDescView;
@property (nonatomic) IBOutlet NSTextView *logView;

@end
