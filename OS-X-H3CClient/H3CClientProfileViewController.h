//
//  H3CClientProfileStorage.h
//  H3CClientX
//
//  Created by Arthas on 6/8/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "H3CClientBackend.h"

@interface H3CClientProfileViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) NSUserDefaults *config;
@property (nonatomic) NSMutableArray *profileArray;
@property (nonatomic) NSString *creatingProfileName;
@property (nonatomic) BOOL hasDuplication;
@property (nonatomic) BOOL isProfileEdited;

@property (nonatomic, weak) IBOutlet NSTableView *profileListView;
@property (nonatomic, weak) IBOutlet NSView *profileEditingView;

@property (nonatomic, weak) IBOutlet NSWindow *customSheetWindow;
@property (nonatomic, weak) IBOutlet NSWindow *preferencesWindow;

@property (nonatomic, weak) IBOutlet NSTextField *usernameField;
@property (nonatomic, weak) IBOutlet NSSecureTextField *passwordField;
@property (nonatomic, weak) IBOutlet NSPopUpButton *interfaceField;
@property (nonatomic, weak) IBOutlet NSButton *defaultField;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

@end
