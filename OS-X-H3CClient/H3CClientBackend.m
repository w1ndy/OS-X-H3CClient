//
//  H3CClientBackend.m
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import "H3CClientBackend.h"

#import <pcap/pcap.h>

@implementation H3CClientBackend

- (id)init
{
    self = [super init];
    if(self) {
        self.connectionState = Disconnected;
        self.globalConfiguration = [NSUserDefaults standardUserDefaults];
        self.adapterList = [self getAdapterList];
    }
    return self;
}

- (void)connect
{
    self.connectionState = Connecting;
}

- (void)disconnect
{
    self.connectionState = Disconnecting;
}

- (NSDictionary *)getAdapterList
{
    NSMutableDictionary *adapters = [NSMutableDictionary new];
    NSDictionary *networkServices = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Preferences/SystemConfiguration/preferences.plist"][@"NetworkServices"];
    for (id key in networkServices)
    {
        id interface = networkServices[key];
        if (interface[@"Interface"])
            [adapters setObject:interface[@"Interface"][@"DeviceName"] forKey:interface[@"UserDefinedName"]];
    }
    return adapters;
}

@end
