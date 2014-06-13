//
//  H3CClientProfileStorage.m
//  H3CClientX
//
//  Created by Arthas on 6/8/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import "H3CClientProfileViewController.h"
#import "H3CClientAppDelegate.h"

@implementation H3CClientProfileViewController

- (id)init
{
    self = [super init];
    if(self) {
        self.config = [NSUserDefaults standardUserDefaults];
        /*NSArray *arr = [self.config arrayForKey:@"profiles"];
        if(!arr) {
            self.profiles = [NSMutableArray new];
        } else {
            self.profiles = [arr mutableCopy];
        }*/
    }
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    //NSLog(@"data fetched: %lu", self.profiles.count);
    return ((NSArray *)self.profileArrayController.arrangedObjects).count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return self.profileArrayController.arrangedObjects[row][@"name"];
}

- (void)tableViewSelectionDidChange:(id)notification
{
}

- (void)addNewProfile
{
    NSLog(@"%@", self.profileArrayController.arrangedObjects);
    [self.preferencesWindow beginSheet:self.customSheetWindow completionHandler:nil];
}

- (void)removeSelectedProfile
{
    NSAlert *alert = [NSAlert new];
    
    NSInteger selected = self.profileListView.selectedRow;
    if(selected == -1) return ;
    alert.messageText = [NSString stringWithFormat: @"Are you sure to remove profile %@", self.profileArrayController.arrangedObjects[selected][@"name"]];
    alert.informativeText = @"Removed profile will be unrecoverable.";
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert addButtonWithTitle:@"Remove"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:self.preferencesWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self.profileArrayController removeObjectAtArrangedObjectIndex:selected];
            [self.profileListView reloadData];
            //[self.config setObject:self.profileArrayController.arrangedObjects forKey:@"profiles"];
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
    NSLog(@"%@", self.profileName);
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"name"] = self.profileName;
    dict[@"username"] = @"";
    dict[@"password"] = @"";
    dict[@"interface"] = @"";
    
    [self.profileArrayController addObject:dict];
    [self.profileListView reloadData];
    [self.profileListView selectRowIndexes:[NSIndexSet indexSetWithIndex:(((NSArray *)self.profileArrayController.arrangedObjects).count - 1)] byExtendingSelection:NO];
    //[self.config setObject:self.profileArrayController.arrangedObjects forKey:@"profiles"];
    [self closeSheet:sender];
}

- (IBAction)closeSheet:(NSButton *)sender
{
    self.profileName = @"";
    [self.preferencesWindow endSheet:self.customSheetWindow];
}

@end
