#ifndef		__GLOBAL__H__
#define		__GLOBAL__H__

//	EAP_HEAD  CODE
#define		EAP_REQUEST		0x01
#define		EAP_RESPONSE		0x02
#define		EAP_SUCCESS		0x03
#define		EAP_FAILURE		0x04
#define		EAP_OTHER			0x0a
//	EAP DATA	TYPE
#define		EAP_IDENTIFY		0x01
#define		EAP_NOTIFICATION	0x02
#define		EAP_MD5			0X04
#define		EAP_LOGOUT			0X08
#define		EAP_ERROR			0X09
#define		EAP_KEEPONLINE	0X14

typedef	unsigned int		DWORD;
typedef	unsigned short	WORD;
typedef	unsigned char		BYTE;

typedef	unsigned char 		u_char8;
typedef	unsigned char		u_char;
typedef	unsigned short	u_short16;
typedef	unsigned short	u_short;

#include	<string>
#define		MAXINTERFACES		64

struct InterfaceInfo
{
	std::string name ;
	std::string ipaddr;
	int macaddr[6];
};

#pragma pack(push) 
#pragma pack(1)

typedef struct UserData
{
	char username[50];
	char password[50];
	u_char8 ip[4];
	u_char8 mac[6];
	char nic[60];
	char nicdes[60];

	char morb;		/* multicast or broadcast to trigger authentication */
	char dhcp;		
	char updateip;	
	char multisend;	/* multicasting send data frame */
	char relogin;	/* relogin after 90 seconds since disconnected */

	char autologin;	
	char rempwd;	/* remember passwd */
}USERDATA, *PUSERDATA;

typedef struct Ethhdr
{
	u_char8	DestMAC[6];
	u_char8	SourMAC[6];
	u_short	EthType;
}ETHHDR, *PETHHDR;

typedef struct Pkthdr
{
	u_char8	DestMAC[6];
	u_char8	SourMAC[6];
	u_char8 EthType[2];

	u_char8 Version;
	u_char8	PktType;
	u_short Len1;
	
	u_char8	Code;
	u_char8	Id;
	u_short Len2;

	u_char8 EapType;
}PKTHDR, *PPKTHDR, LOGINFRM, *PLOGINFRM, LOGOUTFRM, *PLOGOUTFRM;

typedef struct VersionFrm
{
	PKTHDR	Hdr;
	u_char8 Version[50];
}VERSIONFRM, *PVERSIONFRM;

typedef struct UsernameFrm
{
	PKTHDR	Hdr;
	u_char8 Unknown[2];
	u_char8 Ip[4];
	u_char8 Username[50];
}USERNAMEFRM, *PUSERNAMEFRM;

typedef struct PasswordFrm
{
	PKTHDR	Hdr;
	u_char8 Unknown[1];
	u_char8 Md5Pwd[16];
	u_char8 Username[50];
}PASSWORDFRM, *PPASSWORDFRM;

typedef struct KeeponlineFrm
{
	PKTHDR	Hdr;
	u_char8 UseProxy;
	u_char8 Unknown1[2]; //0x16 0x20
	u_char8 Magic[32];
	u_char8 Unknown2[2]; //0x15 0x04
	u_char8 Ip[4];
	u_char8 Username[20];
}KEEPONLINEFRM,*PKEEPONLINEFRM;

typedef struct TokenFrm
{
	PKTHDR	Hdr;
	u_char Identifier[4]; //0x23 0x44 0x23 0x31
	u_char Token[33];
}TOKENFRM, *PTOKENFRM;

#pragma pack(pop) /* restore pack  config */

#endif	//	__GLOBAL__H__
