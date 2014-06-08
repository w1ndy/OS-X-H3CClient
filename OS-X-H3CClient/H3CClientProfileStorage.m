//
//  H3CClientProfileStorage.m
//  H3CClientX
//
//  Created by Arthas on 6/8/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import "H3CClientProfileStorage.h"
#import "H3CClientAppDelegate.h"

@implementation H3CClientProfileStorage

- (id)init
{
    self = [super init];
    if(self) {
        self.config = [NSUserDefaults standardUserDefaults];
        NSArray *arr = [self.config arrayForKey:@"profiles"];
        if(arr == nil) {
            self.profiles = [NSMutableArray new];
        } else {
            self.profiles = [arr mutableCopy];
        }
    }
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.profiles.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return self.profiles[row][@"name"];
}

- (void)tableViewSelectionDidChange:(id)notification
{
    //self.profileEditingView.hidden = NO;
}

- (void)addNewProfile
{
    [self.preferencesWindow beginSheet:self.customSheet completionHandler:nil];
    //[[NSApp delegate] beginSheet:self.customSheet completionHandler:nil];
    //[NSApp beginSheet:self.customSheet completionHandler:^(NSModalResponse returnCode) {}];
    /**/
}

- (void)removeSelectedProfile
{
    NSAlert *alert = [NSAlert new];
    
    NSInteger selected = self.tableView.selectedRow;
    if(selected == -1) return ;
    alert.messageText = [NSString stringWithFormat: @"Are you sure to remove profile %@", self.profiles[selected][@"name"]];
    alert.informativeText = @"Removed profile will be unrecoverable.";
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert addButtonWithTitle:@"Remove"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:self.preferencesWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self.profilesArrayController removeObjectAtArrangedObjectIndex:selected];
            //[self willChangeValueForKey:@"profiles"];
            //[self.profiles removeObjectAtIndex:selected];
            //[self didChangeValueForKey:@"profiles"];
            [self.tableView reloadData];
            [self.config setObject:self.profiles forKey:@"profiles"];
        }
    }];
}

- (IBAction)selectSegmentControl:(NSSegmentedControl *)sender
{
    switch([sender selectedSegment]) {
        case 0:
            [self addNewProfile];
            break;
        case 1:
            [self removeSelectedProfile];
            break;
        default:
            NSLog(@"unknown segment chosen.");
    }
}

- (IBAction)willAddNewProfile:(NSButton *)sender
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"name"] = self.profileName;
    dict[@"username"] = @"";
    dict[@"password"] = @"";
    dict[@"interface"] = @"";
    [self.profilesArrayController addObject:dict];
    //[self willChangeValueForKey:@"profiles"];
    //[self.profiles addObject:dict];
    //[self didChangeValueForKey:@"profiles"];
    [self.tableView reloadData];
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(self.profiles.count - 1)] byExtendingSelection:NO];
    [self.config setObject:self.profiles forKey:@"profiles"];
    [self closeSheet:sender];
}

- (IBAction)closeSheet:(NSButton *)sender
{
    self.profileName = @"";
    [self.preferencesWindow endSheet:self.customSheet];
}

@end
