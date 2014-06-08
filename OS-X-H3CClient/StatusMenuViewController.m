//
//  StatusMenuViewController.m
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import "StatusMenuViewController.h"

#import <QuartzCore/QuartzCore.h>

@interface StatusMenuViewController ()

@end

@implementation StatusMenuViewController

- (id)initWithBackend:(H3CClientBackend *)backend
{
    self = [super initWithNibName:@"StatusMenu" bundle:nil];
    if (self) {
        // Initialization code here.
        self.backend = backend;
        
        [self loadView];
        [self.backend addObserver:self forKeyPath:@"connectionState" options:NSKeyValueObservingOptionNew context:nil];
        
        self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        self.statusItem.menu = self.statusMenu;
        self.statusItem.highlightMode = YES;
        NSImageView *statusView = ((NSWindow *)[self.statusItem valueForKey:@"window"]).contentView;
        statusView.imageScaling = NSImageScaleProportionallyDown;
        self.statusItem.image = [NSImage imageNamed:@"AppIcon"];
        self.statusItem.alternateImage = [NSImage imageNamed:@"AlternateAppIcon"];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"connectionState"]) {
        enum ConnectionState newState;
        [change[@"new"] getValue:&newState];
        switch(newState) {
            case Disconnected:
                [self.connectView setEnabled:YES];
                [self.connectView setTitle:@"Connect"];
                break;
            case Connected:
                [self.connectView setEnabled:YES];
                [self.connectView setTitle:@"Disconnect"];
                break;
            case Connecting:
                [self.connectView setEnabled:NO];
                [self.connectView setTitle:@"Connecting…"];
                break;
            case Disconnecting:
                [self.connectView setEnabled:NO];
                [self.connectView setTitle:@"Disconnecting…"];
                break;
        }
    }
}
- (IBAction)onToggleConnection:(id)sender {
    switch(self.backend.connectionState) {
        case Disconnected:
            [self.backend connect];
            break;
        case Connected:
            [self.backend disconnect];
            break;
        default:
            NSLog(@"error: toggle failed, bad status");
    }
}

- (IBAction)onPreferences:(id)sender {
    [self.delegate showPreferences];
}

@end
