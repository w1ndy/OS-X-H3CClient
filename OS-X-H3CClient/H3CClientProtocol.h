//
//  H3CClientProtocol.h
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#define    ETHERNET_TYPE       0x888e
#define    PACKET_VERSION      0x01

#define    TOKEN_PREDECESSOR   0x1620
#define    TOKEN_SUCCESSOR     0x1504

#define    USERNAME_PADDING    0x1504
#define    PASSWORD_PADDING    0x04

#define    MAX_LENGTH          64

//    EAP_HEAD  CODE
#define    EAP_REQUEST         0x01
#define    EAP_RESPONSE        0x02
#define    EAP_SUCCESS         0x03
#define    EAP_FAILURE         0x04
#define    EAP_OTHER           0x0a

//    EAP PACKET  TYPE
#define    EAPOL_START         0x01
#define    EAPOL_LOGOUT        0x02

//    EAP DATA    TYPE
#define    EAP_IDENTIFY        0x01
#define    EAP_NOTIFICATION    0x02
#define    EAP_MD5             0X04
#define    EAP_LOGOUT          0X08
#define    EAP_ERROR           0X09
#define    EAP_KEEPONLINE      0X14

typedef unsigned char   BYTE;
typedef unsigned short  USHORT;

typedef struct
{
    BYTE value[6];
}
HWADDR;

typedef struct
{
    HWADDR  dest;
    HWADDR  source;
    USHORT  type;
}
EthernetFrame;


typedef struct
{
    EthernetFrame ethernet;
    
    BYTE    version;
    BYTE    type;
    USHORT  len1;
    
    BYTE    code;
    BYTE    pid;
    USHORT  len2;
    
    BYTE    eaptype;
}
PacketFrame, DiscoveryFrame, LogoutFrame;


typedef struct
{
    PacketFrame header;
    
    BYTE version[50];
}
VersionFrame;


typedef struct
{
    PacketFrame header;
    
    USHORT padding;
    BYTE ipaddr[4];
    BYTE username[MAX_LENGTH + 1];
}
UsernameFrame;


typedef struct
{
    PacketFrame header;
    
    BYTE padding;
    BYTE password[16];
    BYTE username[MAX_LENGTH + 1];
}
PasswordFrame;


typedef struct
{
    PacketFrame header;
    
    BYTE useproxy;
    USHORT pred;
    //BYTE reserved1[2]; //0x16 0x20
    BYTE token[32];
    USHORT succ;
    //BYTE reserved2[2]; //0x15 0x04
    BYTE ipaddr[4];
    BYTE username[MAX_LENGTH + 1];
}
HeartbeatFrame;


typedef struct
{
    PacketFrame header;
    
    BYTE identifier[4]; //0x23 0x44 0x23 0x31
    BYTE token[32];
}
TokenFrame;
