//
//  H3CClientBackend.h
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import <Foundation/Foundation.h>

enum ConnectionState
{
    Disconnected,
    Connecting,
    Disconnecting,
    Connected
};

@interface H3CClientBackend : NSObject

@property (nonatomic) enum ConnectionState connectionState;
@property (nonatomic) NSDictionary *adapterList;
@property (nonatomic) NSUserDefaults *globalConfiguration;

- (id)init;
- (void)connect;
- (void)disconnect;

@end
