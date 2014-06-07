//
//  H3CClientConnector.m
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import "H3CClientConnector.h"
#import "H3CClientProtocol.h"

#import <pcap/pcap.h>
#import <sys/types.h>
#import <sys/param.h>
#import <sys/ioctl.h>
#import <sys/socket.h>
#import <sys/times.h>
#import <net/if.h>
#import <netinet/in.h>
#import <net/if_dl.h>
#import <net/if_arp.h>
#import <arpa/inet.h>
#import <errno.h>
#import <ifaddrs.h>

#import <CommonCrypto/CommonDigest.h>

pcap_t *device;
HWADDR hwaddr;

const HWADDR MulticastHardwareAddress = {
    .value = {0x01, 0x80, 0xc2, 0x00, 0x00, 0x03}
};

@implementation H3CClientConnector

- (id)init
{
    self = [super init];
    if(self) {
        device = nil;
    }
    return self;
}

- (BOOL)openAdapter:(NSString *)interfaceName
{
    if(device)
        [self closeAdapter];
    
    struct ifaddrs *if_addrs = NULL, *if_addr = NULL;
    BOOL found = NO;
    
	if (0 == getifaddrs(&if_addrs)) {
		for (if_addr = if_addrs; if_addr != NULL && !found; if_addr = if_addr->ifa_next) {
            if(strcmp(if_addr->ifa_name, [interfaceName UTF8String]) == 0) {
                if (if_addr->ifa_addr != NULL && if_addr->ifa_addr->sa_family == AF_LINK) {
                    struct sockaddr_dl* sdl = (struct sockaddr_dl *)if_addr->ifa_addr;
                    if (6 == sdl->sdl_alen) {
                        for(int i = 0; i < 6; i++)
                            hwaddr.value[i] = ((unsigned char *)LLADDR(sdl))[i];
                        found = YES;
                    }
				}
            }
        }
		freeifaddrs(if_addrs);
    } else {
        NSLog(@"getifaddrs() failed: %s", strerror(errno));
	}
    
    if(!found) {
        NSLog(@"adapter not found");
        return NO;
    }
    
    bpf_u_int32 netmask = 0;
	char pcap_filter[100];	//filter space
	struct bpf_program pcap_fp;	//hold the compiled filter.
	char errbuf[PCAP_ERRBUF_SIZE] = "";
    
	//open adapter
    NSLog(@"opening adapter %@...", interfaceName);
	if (!(device = pcap_open_live([interfaceName UTF8String],	// name of the device
                                256,	// portion of the packet to capture, max 65536
                                0,	// promiscuous mode closed
                                100,	// read timeout
                                errbuf)))	// error buffer
	{
        NSLog(@"pcap_open_live() error: %s", errbuf);
	    return NO;
	}
    
    if (pcap_setnonblock(device, 1, errbuf) == -1) {
        NSLog(@"pcap_setnonblock() error: %s", errbuf);
        pcap_close(device);
        return NO;
    }
    
	//set filter to receive frame of 802.1X only
	sprintf(pcap_filter, "ether dst %02X:%02X:%02X:%02X:%02X:%02X and ether proto 0x888e", hwaddr.value[0], hwaddr.value[1], hwaddr.value[2], hwaddr.value[3], hwaddr.value[4], hwaddr.value[5]);
    NSLog(@"setting packet filter %s...", pcap_filter);
    
	if (pcap_compile(device, &pcap_fp, pcap_filter, 0, netmask) == -1) {
        NSLog(@"pcap_compile() failed");
        pcap_close(device);
	    return NO;
    }
    
	if (pcap_setfilter(device, &pcap_fp) == -1) {
        NSLog(@"pcap_setfilter() failed");
        pcap_close(device);
	    return NO;
    }
    
    return YES;
}

- (void)closeAdapter
{
    if(device) {
        pcap_close(device);
        device = nil;
    }
}

- (BOOL)findServer
{
    DiscoveryFrame frame;
    
    if(!device) {
        NSLog(@"no adapter found.");
        return NO;
    }
    
    memset(&frame, 0, sizeof(frame));
    [self makeEthernetFrame:(EthernetFrame *)&frame destination:MulticastHardwareAddress];
    frame.header.version = PACKET_VERSION;
    frame.header.type = EAPOL_START;
    
    NSLog(@"sending discovery packet...");
    if(pcap_sendpacket(device, (BYTE *)&frame, 60) != 0) {
        NSLog(@"failed to send packet: %s", strerror(errno));
        return NO;
    }
    
    return YES;
}

 - (void)logout:(HWADDR)serverAddress;
{
    LogoutFrame frame;
    
    if(!device) {
        NSLog(@"no adapter found.");
        return ;
    }
    
    memset(&frame, 0, sizeof(frame));
    [self makeEthernetFrame:(EthernetFrame *)&frame destination:serverAddress];
    frame.header.version = PACKET_VERSION;
    frame.header.type = EAPOL_LOGOUT;
    
    NSLog(@"sending logout packet...");
    if(pcap_sendpacket(device, (BYTE *)&frame, 60) != 0) {
        NSLog(@"failed to send packet: %s", strerror(errno));
    }
}

- (BOOL)keepOnlineWithId:(BYTE)pid userName:(NSString *)userName token:(BYTE *)token on:(HWADDR)serverAddress;
{
    HeartbeatFrame frame;
    size_t length = [userName length];
    length = (length > MAX_LENGTH) ? MAX_LENGTH : length;
    size_t pktsize = sizeof(HeartbeatFrame) - MAX_LENGTH + length + 1;
    
    if(!device) {
        NSLog(@"no adapter found.");
        return NO;
    }
    
    memset(&frame, 0, sizeof(frame));
    [self makeEthernetFrame:(EthernetFrame *)&frame destination:serverAddress];
	frame.header.len1 = frame.header.len2 = htons(pktsize);
    frame.header.version = PACKET_VERSION;
    frame.header.code = EAP_RESPONSE;
    frame.header.pid = pid;
    frame.header.eaptype = EAP_KEEPONLINE;
    frame.useproxy = 0;
    frame.pred = htons(TOKEN_PREDECESSOR);
    memcpy(&(frame.token), token, 32);
    frame.succ = htons(TOKEN_SUCCESSOR);
    memcpy(frame.username, [userName UTF8String], length);
    
    NSLog(@"sending heartbeat packet...");
    if(pcap_sendpacket(device, (BYTE *)&frame, (int)pktsize) != 0) {
        NSLog(@"failed to send packet: %s", strerror(errno));
        return NO;
    }
    return YES;
}

- (BOOL)verifyUserName:(NSString *)userName withId:(BYTE)pid on:(HWADDR)serverAddress
{
    UsernameFrame frame;
    size_t length = [userName length];
    length = (length > MAX_LENGTH) ? MAX_LENGTH : length;
    size_t pktsize = length + 0x0b;
    
    if(!device) {
        NSLog(@"no adapter found.");
        return NO;
    }
    
    memset(&frame, 0, sizeof(frame));
    [self makeEthernetFrame:(EthernetFrame *)&frame destination:serverAddress];
    frame.header.version = PACKET_VERSION;
    frame.header.len1 = frame.header.len2 = htons(pktsize);
    frame.header.code = EAP_RESPONSE;
    frame.header.pid = pid;
    frame.header.eaptype = EAP_IDENTIFY;
    frame.padding = htons(USERNAME_PADDING);
    memcpy(frame.username, [userName UTF8String], length);
    
    for(int i = 0; i < pktsize; i++) {
        if(i % 10 == 0) puts("");
        printf("%02X ", ((BYTE*)&frame)[i]);
    }
    
    NSLog(@"verifying username...");
    if(pcap_sendpacket(device, (BYTE *)&frame, 60) != 0) {
        NSLog(@"failed to send packet: %s", strerror(errno));
        return NO;
    }
    return YES;
}

- (void)hashPassword:(NSString *)password withId:(BYTE)pid seed:(BYTE *)seed to:(BYTE *)buf
{
    BYTE tmp[1 + MAX_LENGTH + 16];
    size_t pwdlen = [password length];
    pwdlen = (pwdlen > MAX_LENGTH) ? MAX_LENGTH : pwdlen;
    
    tmp[0] = pid;
    memcpy(tmp + 1, [password UTF8String], pwdlen);
    memcpy(tmp + 1 + pwdlen, seed, 16);
    CC_MD5(tmp, (unsigned int)pwdlen + 17, buf);
}

- (BOOL)verifyPassword:(NSString *)password withId:(BYTE)pid userName:(NSString *)userName seed:(BYTE *)seed on:(HWADDR)serverAddress
{
    PasswordFrame frame;
    size_t length = [userName length];
    length = (length > MAX_LENGTH) ? MAX_LENGTH : length;
    size_t pktsize = length + 0x16;
    
    if(!device) {
        NSLog(@"no adapter found.");
        return NO;
    }
    
    memset(&frame, 0, sizeof(frame));
    [self makeEthernetFrame:(EthernetFrame *)&frame destination:serverAddress];
    frame.header.version = PACKET_VERSION;
    frame.header.len1 = frame.header.len2 = htons(pktsize);
    frame.header.code = EAP_RESPONSE;
    frame.header.pid = pid;
    frame.header.eaptype = EAP_MD5;
    frame.padding = PASSWORD_PADDING;
    [self hashPassword:password withId:pid seed:seed to:frame.password];
    memcpy(frame.username, [userName UTF8String], length);
    
    for(int i = 0; i < 60; i++) {
        if(i % 10 == 0) puts("");
        printf("%02X ", ((BYTE*)&frame)[i]);
    }
    NSLog(@"verifying password...");
    if(pcap_sendpacket(device, (BYTE *)&frame, 60) != 0) {
        NSLog(@"failed to send packet: %s", strerror(errno));
        return NO;
    }
    return YES;
}

- (void)calcAscii:(BYTE *)buf
{
    unsigned short Res;
	unsigned int dEBX,dEBP;
	unsigned int dEDX = 0x10;
	unsigned int mSalt[4] = {0x56657824,0x56745632,0x97809879,0x65767878};
    
	unsigned int dECX = *((unsigned int*)buf);
	unsigned int dEAX = *((unsigned int*)(buf + 4));
    
	dEDX *= 0x9E3779B9;
    
	while(dEDX != 0)
	{
		dEBX = dEBP = dECX;
		dEBX >>= 5;
		dEBP <<= 4;
		dEBX ^= dEBP;
		dEBP = dEDX;
		dEBP >>= 0x0B;
		dEBP &= 3;
		dEBX += mSalt[dEBP];
		dEBP = dEDX;
		dEBP ^= dECX;
		dEDX += 0x61C88647;
		dEBX += dEBP;
		dEAX -= dEBX;
		dEBX = dEAX;
		dEBP = dEAX;
		dEBX >>= 5;
		dEBP <<= 4;
		dEBX ^= dEBP;
		dEBP = dEDX;
		dEBP &= 3;
		dEBX += mSalt[dEBP];
		dEBP = dEDX;
		dEBP ^= dEAX;
		dEBX += dEBP;
		dECX -= dEBX;
	}
    
    
	Res = dECX & 0xffff;
	*buf = Res & 0xff;
	*(buf+1) = (Res & 0xff00) >> 8;
    
	Res = dECX & 0xffff0000 >> 16;
	*(buf+2) = Res & 0xff;
	*(buf+3) = (Res & 0xff00) >> 8;
    
	Res = dEAX & 0xffff;
	*(buf+4) = Res & 0xff;
	*(buf+5) = (Res & 0xff00) >> 8;
    
	Res = dEAX & 0xffff0000 >> 16;
	*(buf+6) = Res & 0xff;
	*(buf+7) = (Res & 0xff00) >> 8;
}

- (BOOL)parseTokenFrame:(TokenFrame *)frame to:(BYTE *)token
{
    if(frame->identifier[0] == 0x23 &&
       frame->identifier[1] == 0x44 &&
       frame->identifier[2] == 0x23 &&
       frame->identifier[3] == 0x31) {
        memcpy(token, frame->token, 32);
        BYTE result[33];
        for(int i = 0; i < 32; i += 8)
            [self calcAscii:(token + i)];
        CC_MD5(token, 32, result);
        memcpy(token, result, 16);
        CC_MD5(token, 16, result);
        memcpy(token + 16, result, 16);
        return YES;
    }
    return NO;
}

- (BOOL)nextPacket:(const PacketFrame **)ptr
{
	struct pcap_pkthdr *header;
	const BYTE *data;
    fd_set fds;
    struct timeval tv;
    int r;
    
    if(!device) {
        NSLog(@"no adapter found.");
        return NO;
    }
    
    int fd = pcap_get_selectable_fd(device);
    FD_ZERO(&fds);
    FD_SET(fd, &fds);
    tv.tv_sec = 90;
    tv.tv_usec = 0;
    
    NSLog(@"fd: %d", fd);
    r = select(fd + 1, &fds, nil, nil, &tv);
    if(r == 0) {
        NSLog(@"read timeout, disconnecting...");
        return NO;
    } else if(r < 0) {
        NSLog(@"select() failed: %s", strerror(errno));
        return NO;
    }
    
    while((r = pcap_next_ex(device, &header, &data)) == 0) {
        NSLog(@"timeout");
        sleep(5);
    }
    if(r == 0) {
        NSLog(@"oh fuck my life");
    } else if(r < 0) {
        NSLog(@"pcap_next_ex() failed: %s", strerror(errno));
        return NO;
    }
    
    *ptr = (const PacketFrame *)data;
    return YES;
}

- (void)makeEthernetFrame:(EthernetFrame *)frame destination:(HWADDR)dest
{
    memcpy(&(frame->dest), &dest, sizeof(HWADDR));
    memcpy(&(frame->source), &hwaddr, sizeof(HWADDR));
    frame->type = htons(ETHERNET_TYPE);
}

@end
