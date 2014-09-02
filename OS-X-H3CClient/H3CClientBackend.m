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

NSDictionary *_adapterList;

- (id)init
{
    self = [super init];
    if(self) {
        _adapterList = nil;
        self.connectionState = Disconnected;
        self.globalConfiguration = [NSUserDefaults standardUserDefaults];
        //self.adapterList = [self getAdapterList];
        self.connector = [[H3CClientConnector alloc] init];
    }
    return self;
}

- (void)sendUserNotificationWithDescription:(NSString *)desc
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"H3CClientX";
    notification.informativeText = desc;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)connect
{
    self.connectionState = Connecting;
    dispatch_async(dispatch_get_global_queue(0, 0), ^(){
        NSLog(@"connecting...");
        
        NSArray *profiles = [self.globalConfiguration objectForKey:@"profiles"];
        if([profiles count] == 0) {
            [self sendUserNotificationWithDescription:@"Please add a profile before connecting."];
            return ;
        }
        long int selected = [self.globalConfiguration integerForKey:@"default"];
        if(selected == -1) {
            [self sendUserNotificationWithDescription:@"No default profile set."];
            return ;
        }
        NSDictionary *dict = [profiles objectAtIndex:selected];
        NSString *userName = dict[@"username"];
        NSString *password = dict[@"password"];
        NSString *adapterName = dict[@"interface"];
        if(userName == nil || [userName isEqualToString:@""] || password == nil || [password isEqualToString:@""]) {
            [self sendUserNotificationWithDescription:@"Username and password are required."];
            self.connectionState = Disconnected;
            return ;
        }
        
        self.userName = userName;
        if(![self.connector openAdapter:adapterName]) {
            [self sendUserNotificationWithDescription:@"Failed to open network adapter."];
            self.connectionState = Disconnected;
            return ;
        }
        
        if(![self.connector findServer]) {
            [self sendUserNotificationWithDescription:@"Cannot find authentication server."];
            self.connectionState = Disconnected;
            return ;
        }
        
        self.timeConnected = time(NULL);
        [self startDaemonWithUserName:userName password:password];
        self.connectionState = Disconnected;
        return ;
        
    });
}

- (void)disconnect
{
    self.connectionState = Disconnecting;
    [self.connector breakLoop];
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

- (void)startDaemonWithUserName:(NSString *)userName password:(NSString *)password
{
    const PacketFrame *frame;
    HWADDR srvaddr;
    BOOL srvfound = NO;
    BYTE token[32];
    
    while([self.connector nextPacket:&frame withTimeout:60]) {
        if(frame == nil) continue;
        switch(frame->code) {
            case EAP_REQUEST:
                switch(frame->eaptype) {
                    case EAP_KEEPONLINE:
                        NSLog(@"received EAP_REQUEST/EAP_KEEPONLINE");
                        if(srvfound && ![self.connector keepOnlineWithId:frame->pid userName:userName token:token on:srvaddr]) {
                            [self sendUserNotificationWithDescription:@"Failed to communicate with server."];
                            self.connectionState = Disconnecting;
                        }
                        break;
                    case EAP_IDENTIFY:
                        NSLog(@"received EAP_REQUEST/EAP_IDENTIFY");
                        if(!srvfound) {
                            memcpy(&srvaddr, &(frame->ethernet.source), sizeof(HWADDR));
                            srvfound = YES;
                        }
                        if(![self.connector verifyUserName:userName withId:frame->pid on:srvaddr]) {
                            [self sendUserNotificationWithDescription:@"Failed to communicate with server."];
                            self.connectionState = Disconnecting;
                        }
                        break;
                    case EAP_MD5:
                        NSLog(@"received EAP_REQUEST/EAP_MD5");
                        if(srvfound && ![self.connector verifyPassword:password withId:frame->pid userName:userName seed:((PasswordFrame *)frame)->password on:srvaddr]) {
                            [self sendUserNotificationWithDescription:@"Failed to communicate with server."];
                            self.connectionState = Disconnecting;
                        }
                        break;
                    default:
                        NSLog(@"received EAP_REQUEST/UNKNOWN %d", frame->eaptype);
                }
                break;
            case EAP_SUCCESS:
                NSLog(@"received EAP_SUCCESS");
                [self sendUserNotificationWithDescription:@"Authenticated successfully."];
                [self.connector updateIP];
                self.connectionState = Connected;
                break;
            case EAP_FAILURE:
                NSLog(@"received EAP_FAILURE");
                [self sendUserNotificationWithDescription:@"Failed to authenticate."];
                self.connectionState = Disconnecting;
                break;
            case EAP_OTHER:
                NSLog(@"received EAP_OTHER");
                if([self.connector parseTokenFrame:(TokenFrame *)frame to:token])
                    break;
                // Rest ignored.
                break;
            default:
                NSLog(@"received UNKNOWN");
        }
    }
    if(self.connectionState == Disconnecting) {
        if(srvfound)
            [self.connector logout:srvaddr];
    }
    [self.connector closeAdapter];
    return;
}

- (NSDictionary *)adapterList
{
    if(_adapterList == nil) {
        _adapterList = [self getAdapterList];
    }
    return _adapterList;
}

- (NSString*)getUserName
{
    if(self.connectionState == Connected) {
        return self.userName;
    } else {
        return @"N/A";
    }
}

- (NSString*)getIPAddress
{
    if(self.connectionState == Connected) {
        for(int i = 0; i < [[[NSHost currentHost] addresses] count]; i++) {
            if([[[[NSHost currentHost] addresses] objectAtIndex:i] containsString:@":"]) continue;
            else return [[[NSHost currentHost] addresses] objectAtIndex:i];
        }
    }
    return @"No IPv4 address";
}

@end
