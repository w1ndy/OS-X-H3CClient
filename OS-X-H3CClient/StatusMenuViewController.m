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
        self.statusItem.image = [NSImage imageNamed:NSImageNameRefreshFreestandingTemplate];
        /*StatusItemView *statusImageView = [StatusItemView new];
         self.statusMenu.delegate = statusImageView;
         statusImageView.menu = self.statusMenu;
         statusImageView.statusItem = self.statusItem;
         statusImageView.image = [NSImage imageNamed:NSImageNameRefreshFreestandingTemplate];
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        animation.fromValue = @(0.0f);
        animation.toValue = @(-2 * M_PI);
        animation.duration = 1.0f;
        animation.repeatCount = INFINITY;
        NSImageView *spinningView = [NSImageView new];
        spinningView.image = [NSImage imageNamed:NSImageNameRefreshFreestandingTemplate];
        spinningView.wantsLayer = YES;
        [spinningView.layer addAnimation:animation forKey:@"SpinAnimation"];
        NSImageView *statusView = ((NSWindow *)[self.statusItem valueForKey:@"window"]).contentView;
        NSLog(@"%@", statusView);
        //statusView.image = nil;
        spinningView.frame = statusView.frame;
        spinningView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        //[statusView addSubview:spinningView];
        //
        //self.statusItem.view = statusImageView;*/
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

- (IBAction)onExit:(id)sender {
    [NSApp terminate: nil];
}

@end
