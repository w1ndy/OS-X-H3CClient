//
//  H3CClientBackend.h
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "H3CClientConnector.h"

enum ConnectionState
{
    Disconnected,
    Connecting,
    Disconnecting,
    Connected
};

@interface H3CClientBackend : NSObject

@property (atomic) enum ConnectionState connectionState;
@property (nonatomic) NSDictionary *adapterList;
@property (nonatomic) H3CClientConnector *connector;
@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *status;
@property (nonatomic) NSUserDefaults *globalConfiguration;

@property (nonatomic) long int timeConnected;
@property (nonatomic) NSDictionary *trafficStatConnected;
@property (nonatomic) BOOL manualDisconnect;

- (id)init;
- (void)sendUserNotificationWithDescription:(NSString *)desc;
- (void)connect;
- (void)connectUsingProfile:(NSInteger)selected;
- (void)disconnect;
- (NSString*)getUserName;
- (NSString*)getIPAddress;
- (void)updateIP;
- (NSDictionary*)getTrafficStatSinceConnected;

+ (H3CClientBackend*)defaultBackend;

@end
