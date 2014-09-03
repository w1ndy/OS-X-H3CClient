//
//  StatusMenuViewController.m
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import "StatusMenuViewController.h"

#import <QuartzCore/QuartzCore.h>

@implementation StatusMenuViewController

- (id)init
{
    self = [super initWithNibName:@"StatusMenu" bundle:nil];
    if (self) {
        // Initialization code here.
        [self loadView];
        [[H3CClientBackend defaultBackend] addObserver:self forKeyPath:@"connectionState" options:NSKeyValueObservingOptionNew context:nil];
        
        self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        self.statusItem.menu = self.statusMenu;
        self.statusItem.highlightMode = YES;
        //self.statusItem.title = @"H3CClientX";
        //NSImageView *statusView = ((NSWindow *)[self.statusItem valueForKey:@"window"]).contentView;
        //statusView.imageScaling = NSImageScaleProportionallyDown;
        //[image setTemplate:YES];
        [self.statusItem setImage:[NSImage imageNamed:NSImageNameStatusNone]];
        //self.statusItem.alternateImage = [NSImage imageNamed:@"AlternateAppIcon"];
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
                self.statusItem.image = [NSImage imageNamed:NSImageNameStatusNone];
                break;
            case Connected:
                [self.connectView setEnabled:YES];
                [self.connectView setTitle:@"Disconnect"];
                self.statusItem.image = [NSImage imageNamed:NSImageNameStatusAvailable];
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
    switch([H3CClientBackend defaultBackend].connectionState) {
        case Disconnected:
            [[H3CClientBackend defaultBackend] connect];
            break;
        case Connected:
            [[H3CClientBackend defaultBackend] disconnect];
            break;
        default:
            NSLog(@"error: toggle failed, bad status");
    }
}

- (IBAction)onPreferences:(id)sender {
    [self.delegate showPreferences];
}

- (void)onConnectUsing:(id)sender {
    NSArray *profiles = [[H3CClientBackend defaultBackend].globalConfiguration arrayForKey:@"profiles"];
    for(int i = 0; i < [profiles count]; i++) {
        NSDictionary *dict = [profiles objectAtIndex:i];
        if([dict[@"name"] isEqualToString:((NSMenuItem*)sender).title]) {
            [[H3CClientBackend defaultBackend] connectUsingProfile:i];
            break;
        }
    }
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    menu.autoenablesItems = NO;
    NSMenuItem *item = [menu itemWithTitle:@"Connect using"];
    if([H3CClientBackend defaultBackend].connectionState != Disconnected) {
        [item setEnabled:NO];
        [item setSubmenu:nil];
        return ;
    }
    [item setEnabled:YES];
    NSMenu *submenu = [[NSMenu alloc] init];
    submenu.autoenablesItems = NO;
    NSArray *profiles = [[H3CClientBackend defaultBackend].globalConfiguration arrayForKey:@"profiles"];
    if(profiles.count == 0) {
        NSMenuItem *noprof = [[NSMenuItem alloc] init];
        [noprof setTitle:@"No Profile"];
        [noprof setEnabled:NO];
        [submenu addItem:noprof];
    } else {
        for(int i = 0; i < profiles.count; i++) {
            NSDictionary *dict = [profiles objectAtIndex:i];
            NSMenuItem *subitem = [submenu addItemWithTitle:dict[@"name"] action:@selector(onConnectUsing:) keyEquivalent:@""];
            [subitem setTarget:self];
            [subitem setRepresentedObject:subitem];
        }
    }
    [menu setSubmenu:submenu forItem:item];
}
@end
