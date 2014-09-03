//
//  StatusMenuViewController.h
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "H3CClientBackend.h"


@protocol StatusMenuViewControllerDelegate

- (void)showPreferences;

@end

@interface StatusMenuViewController : NSViewController <NSMenuDelegate>

@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) id <StatusMenuViewControllerDelegate> delegate;

@property (nonatomic, weak) IBOutlet NSMenu *statusMenu;
@property (nonatomic, weak) IBOutlet NSMenuItem *connectView;

- (id)init;
- (void)menuNeedsUpdate:(NSMenu *)menu;

@end
