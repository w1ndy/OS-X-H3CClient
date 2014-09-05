//
//  H3CClientConnector.h
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "H3CClientProtocol.h"

@interface H3CClientConnector : NSObject

- (id)init;

- (BOOL)openAdapter:(NSString *)interfaceName;
- (void)closeAdapter;

- (BOOL)findServer;
- (BOOL)keepOnlineWithId:(BYTE)pid userName:(NSString *)userName token:(BYTE *)token on:(HWADDR)serverAddress;
- (BOOL)verifyUserName:(NSString *)userName withId:(BYTE)pid on:(HWADDR)serverAddress;
- (BOOL)verifyPassword:(NSString *)password withId:(BYTE)pid userName:(NSString *)userName seed:(BYTE *)seed on:(HWADDR)serverAddress;
- (BOOL)parseTokenFrame:(TokenFrame *)frame to:(BYTE *)token;
- (NSString*)parseFailureFrame:(FailureFrame *)frame;
- (void)logout:(HWADDR)serverAddress;

- (BOOL)nextPacket:(const PacketFrame **)ptr withTimeout:(int)second;
- (void)updateIP;
- (void)breakLoop;
- (NSMutableDictionary*)getTrafficStat;

@end
