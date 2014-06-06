//
//  H3CClientConnector.m
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import "H3CClientConnector.h"

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

pcap_t *device;

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
    struct ifaddrs *if_addrs = NULL, *if_addr = NULL;
	unsigned char hwaddr[6];
    BOOL found = NO;
    
	if (0 == getifaddrs(&if_addrs)) {
		for (if_addr = if_addrs; if_addr != NULL && !found; if_addr = if_addr->ifa_next) {
            if(strcmp(if_addr->ifa_name, [interfaceName UTF8String]) == 0) {
                if (if_addr->ifa_addr != NULL && if_addr->ifa_addr->sa_family == AF_LINK) {
                    struct sockaddr_dl* sdl = (struct sockaddr_dl *)if_addr->ifa_addr;
                    if (6 == sdl->sdl_alen) {
                        for(int i = 0; i < 6; i++)
                            hwaddr[i] = ((unsigned char *)LLADDR(sdl))[i];
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
	if (!(device = pcap_open_live([interfaceName UTF8String],	// name of the device
                                256,	// portion of the packet to capture, max 65536
                                0,	// promiscuous mode closed
                                10,	// read timeout
                                errbuf)))	// error buffer
	{
        NSLog(@"pcap error: %s", errbuf);
	    return NO;
	}
    
	//set filter to receive frame of 802.1X only
	sprintf(pcap_filter,
            "ether dst %x:%x:%x:%x:%x:%x and ether proto 0x888e",
            hwaddr[0], hwaddr[1], hwaddr[2], hwaddr[3], hwaddr[4], hwaddr[5]);
    
	if (pcap_compile(device, &pcap_fp, pcap_filter, 0, netmask) == -1) {
        NSLog(@"pcap_compile() failed");
	    return NO;
    }
    
	if (pcap_setfilter(device, &pcap_fp) == -1) {
        NSLog(@"pcap_setfilter() failed");
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

@end
