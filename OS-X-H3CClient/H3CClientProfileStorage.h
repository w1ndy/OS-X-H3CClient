//
//  H3CClientProfileStorage.h
//  H3CClientX
//
//  Created by Arthas on 6/8/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "H3CClientBackend.h"

@interface H3CClientProfileStorage : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic) NSMutableArray *profiles;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) NSUserDefaults *config;
@property (nonatomic, weak) IBOutlet NSWindow *customSheet;
@property (nonatomic, weak) IBOutlet NSWindow *preferencesWindow;
@property (nonatomic) NSString *profileName;
@property (nonatomic, weak) IBOutlet NSView *profileEditingView;
@property (nonatomic, weak) IBOutlet NSArrayController *profilesArrayController;

- (id)init;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

@end
