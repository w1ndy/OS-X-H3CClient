//
//  StatusMenuViewController.h
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "H3CClientBackend.h"

@interface StatusMenuViewController : NSViewController

@property (nonatomic, weak) NSWindow *preferencesWindow;
@property (nonatomic, weak) H3CClientBackend *backend;

@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) id delegate;

@property (weak) IBOutlet NSMenu *statusMenu;
@property (weak) IBOutlet NSMenuItem *connectView;

- (id)initWithDelegate:(id)delegate backend:(H3CClientBackend *)backend;

@end


@interface NSObject(WithPreferences)

- (void)showPreferences;

@end