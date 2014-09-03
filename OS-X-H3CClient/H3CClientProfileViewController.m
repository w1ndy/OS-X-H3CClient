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

- (void)awakeFromNib
{
    self.profileListView.dataSource = self;
    self.profileListView.delegate = self;
    self.config = [NSUserDefaults standardUserDefaults];
    NSArray *arrStorage = [self.config arrayForKey:@"profiles"];
    if(arrStorage) {
        self.profileArray = [NSMutableArray new];
        for(id item in arrStorage)
           [self.profileArray addObject:[item mutableCopy]];
    } else
        self.profileArray = [NSMutableArray new];
    [self.profileListView reloadData];
    if([H3CClientBackend defaultBackend].adapterList.count > 0)
        [self.interfaceField addItemsWithTitles:[[H3CClientBackend defaultBackend].adapterList allKeys]];
    else {
        [self.interfaceField setEnabled:NO];
        [self.interfaceField addItemWithTitle:@"No Interface Available"];
    }
    self.isProfileEdited = NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(self.profileArray.count == 0)
        self.profileEditingView.hidden = YES;
    else
        [self tableViewSelectionDidChange:nil];
    return self.profileArray.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return self.profileArray[row][@"name"];
}

- (void)tableViewSelectionDidChange:(id)notification
{
    long int row = self.profileListView.selectedRow;
    if(row >= 0 && row < [self.profileArray count]) {
        self.profileEditingView.hidden = NO;
        self.usernameField.stringValue = self.profileArray[row][@"username"];
        self.passwordField.stringValue = self.profileArray[row][@"password"];
        if(row == [self.config integerForKey:@"default"]) {
            self.defaultField.state = NSOnState;
        } else {
            self.defaultField.state = NSOffState;
        }
        if([self.interfaceField isEnabled]) {
            if([self.profileArray[row][@"interface"] isEqualToString:@""]) {
                [self.profileArray[row] setValue:[[H3CClientBackend defaultBackend].adapterList allKeys][0] forKey:@"interface"];
                [self.config setObject:self.profileArray forKey:@"profiles"];
            }
            BOOL found = NO;
            for(id key in [[H3CClientBackend defaultBackend].adapterList allKeys]) {
                if([[H3CClientBackend defaultBackend].adapterList[key] isEqualToString:self.profileArray[row][@"interface"]]) {
                    [self.interfaceField selectItemWithTitle:key];
                    found = YES;
                    break;
                }
            }
            if(!found) {
                [self.profileArray[row] setValue:[[H3CClientBackend defaultBackend].adapterList allKeys][0] forKey:@"interface"];
                [self.config setObject:self.profileArray forKey:@"profiles"];
                [self.interfaceField selectItemAtIndex:0];
            }
        }
    }
}

- (void)addNewProfile
{
    [self saveProfile:nil];
    [self.preferencesWindow beginSheet:self.customSheetWindow completionHandler:nil];
}

- (void)removeSelectedProfile
{
    NSAlert *alert = [NSAlert new];
    
    NSInteger selected = self.profileListView.selectedRow;
    if(selected == -1) return ;
    alert.messageText = [NSString stringWithFormat: @"Are you sure to remove profile %@", self.profileArray[selected][@"name"]];
    alert.informativeText = @"Removed profile will be unrecoverable.";
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert addButtonWithTitle:@"Remove"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:self.preferencesWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            long int def = [self.config integerForKey:@"default"];
            if(selected == 0) {
                if(self.profileArray.count != 1) {
                    [self.profileListView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected + 1] byExtendingSelection:NO];
                    [self.config setInteger:(def - 1) forKey:@"default"];
                } else {
                    [self.config setInteger:-1 forKey:@"default"];
                }
            } else {
                if(selected == def) {
                    [self.config setInteger:-1 forKey:@"default"];
                } else if(selected < def) {
                    [self.config setInteger:(def - 1) forKey:@"default"];
                }
                [self.profileListView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected - 1] byExtendingSelection:NO];
            }
            [self.profileArray removeObjectAtIndex:selected];
            [self.profileListView reloadData];
            [self.config setObject:self.profileArray forKey:@"profiles"];
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
    dict[@"name"] = self.creatingProfileName;
    dict[@"username"] = @"";
    dict[@"password"] = @"";
    dict[@"interface"] = [self.interfaceField isEnabled] ? [[H3CClientBackend defaultBackend].adapterList allKeys][0] : @"";
    
    [self.profileArray addObject:dict];
    [self.config setObject:self.profileArray forKey:@"profiles"];
    [self.profileListView reloadData];
    [self.profileListView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.profileArray.count - 1] byExtendingSelection:NO];
    [self closeSheet:sender];
}

- (IBAction)closeSheet:(NSButton *)sender
{
    self.creatingProfileName = @"";
    [self.preferencesWindow endSheet:self.customSheetWindow];
}

- (IBAction)saveProfile:(id)sender {
    long int row = [self.profileListView selectedRow];
    if(row < 0) return ;
    self.profileArray[row][@"username"] = self.usernameField.stringValue;
    self.profileArray[row][@"password"] = self.passwordField.stringValue;
    self.profileArray[row][@"interface"] = [H3CClientBackend defaultBackend].adapterList[[self.interfaceField.selectedItem title]];
    [self.config setObject:self.profileArray forKey:@"profiles"];
}

- (IBAction)makeDefaultProfile:(id)sender {
    long int row = self.profileListView.selectedRow;
    switch(self.defaultField.state) {
        case NSOnState:
            [self.config setInteger:row forKey:@"default"];
            break;
        case NSOffState:
            [self.config setInteger:-1 forKey:@"default"];
            break;
    }
}

- (BOOL)hasDuplication
{
    for(NSDictionary *dict in self.profileArray) {
        if([dict[@"name"] isEqualToString:self.creatingProfileName]) return NO;
    }
    return YES;
}

@end
