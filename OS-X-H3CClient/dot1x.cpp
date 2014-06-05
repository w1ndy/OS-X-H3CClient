#include "dot1x.h"

#include "md5.h"

#include <ctime>
#include <netinet/in.h>

#include <sys/types.h>
#include <sys/param.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/times.h>
#include <net/if.h>
#include <netinet/in.h>
#include <net/if_dl.h>
#include <net/if_arp.h>
#include <arpa/inet.h>
#include <errno.h>
#include <ifaddrs.h>
#include <string>
#include <iostream>
#include <cstdlib>
#include <cstring>

#define LOWORD(i)((WORD)(i))  
#define HIWORD(i)((WORD)(((DWORD)(i)>>16)&0xffff)) 

#define LOBYTE(i)((BYTE)(i))  
#define HIBYTE(i)((BYTE)(((WORD)(i)>>8)&0xff)) 

long GetTickCount()
{
    tms tm;
    return times(&tm);
}


namespace NetworkOperation {
using namespace std;

int GetSystemInterfaceInfo(InterfaceInfo * infoarray) 
{
	struct ifaddrs *if_addrs = NULL;
	struct ifaddrs *if_addr = NULL;
	int interfacenum = -1;
	if (0 == getifaddrs(&if_addrs)) {
		interfacenum = 0;
		for (if_addr = if_addrs; if_addr != NULL; if_addr = if_addr->ifa_next) {
			infoarray[interfacenum].name = if_addr->ifa_name;
			cout << infoarray[interfacenum].name << endl;

			if (if_addr->ifa_addr->sa_family == AF_INET) {
				infoarray[interfacenum].ipaddr = inet_ntoa(
					((struct sockaddr_in *)if_addr->ifa_addr)->sin_addr);
			} else {
				infoarray[interfacenum].ipaddr = "";
			}

			if (if_addr->ifa_addr != NULL && if_addr->ifa_addr->sa_family == AF_LINK) {
				struct sockaddr_dl* sdl = (struct sockaddr_dl *)if_addr->ifa_addr;
				if (6 == sdl->sdl_alen) {
					for(int i = 0; i < 6; i++)
						infoarray[interfacenum].macaddr[i] = ((unsigned char *)LLADDR(sdl))[i];
				} else {
					infoarray[interfacenum].macaddr[0] = -1;
				}
			} else {
				infoarray[interfacenum].macaddr[0] = -1;
			}
			interfacenum++;
		}
		freeifaddrs(if_addrs);
	} else {
		cout << "getifaddrs() failed: " << strerror(errno) << endl;
	}

	return interfacenum;
}

HuaweiNetwork::HuaweiNetwork(const string &username, const string &passwd,
				 const string &interfacename, int *ip, int *mac, int bRenew)
{
	USERDATA *m_pData = &m_Data;
	strcpy(m_pData->username, username.c_str());
	strcpy(m_pData->password, passwd.c_str());
	strcpy(m_pData->nic, interfacename.c_str());

	m_pData->ip[0] = ip[0];
	m_pData->ip[1] = ip[1];
	m_pData->ip[2] = ip[2];
	m_pData->ip[3] = ip[3];

	m_pData->mac[0] = mac[0];
	m_pData->mac[1] = mac[1];
	m_pData->mac[2] = mac[2];
	m_pData->mac[3] = mac[3];
	m_pData->mac[4] = mac[4];
	m_pData->mac[5] = mac[5];

	m_pData->morb = 0;
	m_pData->dhcp = bRenew;
	m_pData->multisend = 0;
	m_pData->updateip = 1;
	m_pData->relogin = 0;

	m_fp = NULL;		/* network interface device */

	u_char mcast[6] = { 0x01, 0x80, 0xc2, 0x00, 0x00, 0x03 };	/* multicasting address */
	memcpy(m_DestMac, mcast, 6);	/* default address is  multicasting address */
	char cver[14] =
	    { 'C', 'H', ' ', 'V', '2', '.', '4', '0', '-', '0', '3', '2', '6', 0 };
	memcpy(m_ClientVersion, cver, 14);
	srand((unsigned int)time(0));
}

void HuaweiNetwork::run()
{
	struct pcap_pkthdr *header;
	const u_char *pkt_data;

	int res;
	time_t dwTick, dwOldTick;
	dwTick = dwOldTick = clock();
	int flag = 0;
	
	/*  read frames sequentially */
	while ((res = pcap_next_ex(m_fp, &header, &pkt_data)) >= 0) {

	    if (res == 0) {	// Timeout elapsed
			/* use ::GetTickCount() to get the elapsed time */
			dwTick = clock();
			if (dwTick - dwOldTick >= 90000	//ms
				&& m_Data.relogin == 1) {
				message("Reconnecting...");
				dwOldTick = clock();
			}
			continue;
		}

	    PPKTHDR pbuf = (PPKTHDR) pkt_data;
		/* get the source mac address of the frame received */
	    memcpy(m_DestMac, pbuf->SourMAC, 6);	

	    if (pbuf->Code == EAP_REQUEST) {
			switch (pbuf->EapType) {
				case EAP_KEEPONLINE:
//					message("EAP_KEEPONLINE received.");
					SendKeeponline(pbuf->Id);
					dwOldTick = clock();
					//arak 1+d
		
					break;
				case EAP_NOTIFICATION:
					message("EAP_NOTIFICATION received.");
					SendVersion(pbuf->Id);
					break;
				case EAP_IDENTIFY:
					message("EAP_IDENTIFY received.");
					SendUsername(pbuf->Id);
					//arak 1+d
					break;
				case EAP_MD5:
					message("EAP_MD5 received.");
					SendPassword(pbuf->Id,
						 ((PPASSWORDFRM) pkt_data)->Md5Pwd);
					break;
				default:;
			}
	
			continue;
	    }

	    if (pbuf->Code == EAP_SUCCESS) {

			message("Successfully Login.");
			//                          isonline = true;
			if(m_Data.dhcp)
				Connected();
			continue;
	    }

	    if (pbuf->Code == EAP_FAILURE) {

			if (pbuf->EapType == EAP_LOGOUT) {
				message("Logout!");
				//ConnectionInterrupted();
			} else {
				// Network Failure;
				message((const char *) (pkt_data + 0x18));
				// arak 1+d
				//ConnectionInterrupted();
			}
			break;		//jump out of the loop
	    }

	    if (pbuf->Code == EAP_OTHER) {	//there are three frames to handle

			//获取Token
			if(GetToken((PTOKENFRM)pkt_data))
				continue;

	    	//the former is about the client download address, ignore it
			if (flag == 0) {
				flag = 1;
				continue;
			}
			//append information
			u_char a[0xff] = { 0 };
			memcpy(a, pkt_data + 0x1a, *(pkt_data + 0x11) - 4);
			//a[*(pkt_data +0x11)-3] = '\0';
			for (int i = 0; i < 0xff; i++) {
				if (a[0xff - i] == 0x34) {
				a[0xff - i] = '\t';
				a[0xff - i + 1] = '\n';
				break;
				}
			}
			message((const char *)a);

			continue;
	    }
	}
	CloseAdapter();
}

bool HuaweiNetwork::Connect() {
	message("Initializing Network Adapter...");
	if (!OpenAdapter()) {	/* open adapter, set filter and start the thread */
	    message("Network Adapter Initializing Failed.");
	    return false;
	}

	//start(QThread::HighPriority);

	return SendLogin();

	//          Connected();
}

void HuaweiNetwork::DisConnect() {
	//          ConnectionInterrupted();
	if (m_fp) {
	    SendLogout();
	    message("Disconnected.");
	}
}

bool HuaweiNetwork::OpenAdapter() {
	bpf_u_int32 netmask = 0;
	char pcap_filter[100];	//filter space
	struct bpf_program pcap_fp;	//hold the compiled filter.
	char errbuf[PCAP_ERRBUF_SIZE] = "";
	//open adapter
	if (!(m_fp = pcap_open_live(m_Data.nic,	// name of the device
				    256,	// portion of the packet to capture, max 65536
				    0,	// promiscuous mode closed
				    10,	// read timeout
				    errbuf)))	// error buffer
	{
	    //              AfxmessageBox(errbuf);
	    message((const char *) errbuf);
	    return false;
	}
	//set filter to receive frame of 802.1X only
	sprintf(pcap_filter,
		"ether dst %x:%x:%x:%x:%x:%x and ether proto 0x888e",
		m_Data.mac[0], m_Data.mac[1], m_Data.mac[2], m_Data.mac[3],
		m_Data.mac[4], m_Data.mac[5]);
	//  sprintf(pcap_filter, " or ether dst 01:80:c2:00:00:03 and ether proto 0x888e",
	//                                    m_pData->Mac[0],m_pData->Mac[1],m_pData->Mac[2],
	//                                    m_pData->Mac[3],m_pData->Mac[4],m_pData->Mac[5]);

	if (pcap_compile(m_fp, &pcap_fp, pcap_filter, 0, netmask) == -1)
	    return false;

	if (pcap_setfilter(m_fp, &pcap_fp) == -1)
	    return false;

	return true;
}

void HuaweiNetwork::CloseAdapter() {
	if (m_fp != 0) {
	    pcap_close(m_fp);	//shutdown the apdater
	    m_fp = 0;
	}
}

void HuaweiNetwork::SetMd5Buf(PPASSWORDFRM pBuf, const u_char ID, const u_char * chap) {	//digest MD5
	u_char TmpBuf[1 + 64 + 16];
	MD5_CTX md5T;
	u_char digest[16];
	size_t PasswdLen = strlen(m_Data.password);
	TmpBuf[0] = ID;		//   memcpy(TmpBuf + 0x00, ID, 1);
	memcpy(TmpBuf + 0x01, m_Data.password, PasswdLen);
	memcpy(TmpBuf + 0x01 + PasswdLen, chap, 16);
	md5T.MD5Update(TmpBuf, 17 + (int)PasswdLen);
	md5T.MD5Final(digest);
	memcpy(pBuf->Md5Pwd, digest, 16);
    }

void HuaweiNetwork::InitBuf(u_char * buf) {	//initial every frame
	u_char prototype[3] = { 0x88, 0x8e, 0x01 };

	if (m_Data.multisend == 0x00)	//set destination MAC
	    memcpy(buf, m_DestMac, 6);
	memcpy(buf + 6, m_Data.mac, 6);	//set source MAC
	memcpy(buf + 12, prototype, 3);	//set protocol type and its version
}

bool HuaweiNetwork::SendLogin() {	//send the EAPOL-START frame
	u_char buf[100] = { 0 };
	PLOGINFRM pbuf = (PLOGINFRM) buf;

	InitBuf(buf);		//Set Dest MAC, Source MAC, Protocol Type and Version
	if (m_Data.morb == 'b')
	    memset(buf, 0xff, 6);	//broadcast EAPOL-START (by default is multicast)
	pbuf->PktType = 0x01;	//EAPOL-START

	if (!pcap_sendpacket(m_fp, buf, 60)) {
	    message("Login sent");
	    return true;
	}

	return false;
}

bool HuaweiNetwork::SendLogout() {	//send logout frame
	u_char buf[100] = { 0 };
	PLOGOUTFRM pbuf = (PLOGOUTFRM) buf;

	InitBuf(buf);		//set Dest MAC, Source MAC, Protocol Type and Version
	pbuf->PktType = 0x02;	//EAPOL-LOGOUT

	if (!pcap_sendpacket(m_fp, buf, 60)) {
	    message("Disconnecting...");
	    return true;
	}

	return false;
}

bool HuaweiNetwork::SendVersion(const u_char Id) {	//send frame to confirm version 
	/*      u_char buf[100] = {

	   0x2e, 0x25, 0x4d, 0x3b, 0x5f, 0x43, 0x5f,
	   0x5d, 0x40, 0x5d, 0x5f, 0x5e, 0x5c, 0x6d, 0x6d,
	   0x6d, 0x6d, 0x6d, 0x6d, 0x6d,
	 *//*
	   u_char buf[100] = {
	   0x01, 0x80, 0xc2, 0x00, 0x00, 0x03, 0x00, 0x00,
	   0x00, 0x00, 0x00, 0x00, 0x88, 0x8e, 0x01, 0x00,
	   0x00, 0x31, 0x02, 0x01 ,0x00, 0x31, 0x02, 0x01,
	   0x16, // 25 bytes
	   //// version[2] = buf[25]
	   0x1d, 0x09, // 27 bytes
	   ////
	   0x2b, 0x63, 0x07, 0x25, 0x75,
	   0x6e, 0x6f, 0x4b, 0x4e, 0x24, 0x39, 0x45, 0x0f,
	   0x67, 0xd5, 0xa8, 0x3d, 0x0b, // 27+18=45

	   0x02, 0x16, 0x3a, // 45 +3 = 48
	   0x71, 0x38, 0x01, 0x0b, 0x3b, 0x7e, 0x3d, 0x26, 
	   0x7c, 0x7c, 0x17, 0x0b, 0x46, 0x08, 0x32, 0x32, // 48 + 16 = 64
	   0x08, 0x46, 0x0b // 64 + 3 = 67
	   };
	 */
	//  PVERSIONFRM pbuf = (PVERSIONFRM) m_buf;

	// arak +n
	u_char buf[100] = { 0 };
	PVERSIONFRM pbuf = (PVERSIONFRM) buf;
	InitBuf(buf);
	pbuf->Hdr.PktType = 0x00;
	pbuf->Hdr.Len1 = htons(0x31);
	pbuf->Hdr.Code = 0x02;
	pbuf->Hdr.Id = 0x01;
	pbuf->Hdr.Len2 = pbuf->Hdr.Len1;
	pbuf->Hdr.EapType = 0x02;
	GenerateVersion(pbuf->Version);
	// \arak +n
	InitBuf(buf);
	if (!pcap_sendpacket(m_fp, buf, 67)) {
	    message("Finding authentication server...");
	    return true;
	}

	return false;
}
    //    #include <sys/socket.h>
bool HuaweiNetwork::SendUsername(const u_char Id) {	//send username frame
	u_char buf[100] = { 0 };
	PUSERNAMEFRM pbuf = (PUSERNAMEFRM) buf;

	InitBuf(buf);
	pbuf->Hdr.Len1 = htons(strlen(m_Data.username) + 0x0b);
	pbuf->Hdr.Code = 0x02;
	pbuf->Hdr.Id = Id;
	pbuf->Hdr.Len2 = pbuf->Hdr.Len1;
	pbuf->Hdr.EapType = 0x01;
	pbuf->Unknown[0] = 0x15;
	pbuf->Unknown[1] = 0x04;
	if (m_Data.updateip == 0x01)
	    memcpy(pbuf->Ip, m_Data.ip, 4);	//upload host IP
	memcpy(&pbuf->Username, &m_Data.username, strlen(m_Data.username));

	if (!pcap_sendpacket(m_fp, buf, 60)) {
	    message("Verifying User Name ...");
	    return true;
	}

	return false;
}

bool HuaweiNetwork::SendPassword(const u_char Id, const u_char * Chap) {//send passwd frame
	u_char buf[100] = { 0 };
	PPASSWORDFRM pbuf = (PPASSWORDFRM) buf;

	InitBuf(buf);
	pbuf->Hdr.Len1 = htons(strlen(m_Data.username) + 0x16);
	pbuf->Hdr.Code = 0x02;
	pbuf->Hdr.Id = Id;
	pbuf->Hdr.Len2 = pbuf->Hdr.Len1;
	pbuf->Hdr.EapType = 0x04;
	pbuf->Unknown[0] = 0x10;
	SetMd5Buf(pbuf, Id, Chap);
	memcpy(pbuf->Username, m_Data.username, strlen(m_Data.username));

	if (!pcap_sendpacket(m_fp, buf, 60)) {
	    message("Verifying Password ...");
	    return true;
	}

	return false;
}

void HuaweiNetwork::GenerateVersion(u_char * buf) {
	buf[0] = 0x01;
	buf[1] = 0x16;

	unsigned long magic = rand();
	//initial strMagic, store the of string of the hexadecimal value of magic in it*/
	char strMagic[9] = { 0 };
	unsigned char strTemp[4] = { 0 };
	memcpy(strTemp, (unsigned char *) &magic, 4);
	sprintf(strMagic, "%02x%02x%02x%02x", strTemp[0], strTemp[1],
		strTemp[2], strTemp[3]);
	//printf("%s\n",strMagic);
	//initial info of version
	unsigned char version[20];
	memset(version, 0, sizeof(version));
	memcpy(version, m_ClientVersion, strlen(m_ClientVersion));
	memcpy(version + 16, (unsigned char *) &magic, 4);

	//set the variable 20 bytes of the information about version 
	EncodeVersion(strMagic, version, 0x10);
	EncodeVersion("HuaWei3COM1X", version, 0x14);
	memcpy(buf + 2, version, 20);

	//debug 2
	//for(int i=0; i<20; i++)
	//            {printf("%02x ",(unsigned char)version[i]);}
	buf[22] = 0x02;
	buf[23] = 0x16;

	//the last 20 bytes
	char winVersion[20] = { 
		0x3a, 0x71, 0x38, 0x01, 0x0b, 0x3b, 0x7e, 0x3d,
	    0x26, 0x7c, 0x7c, 0x17, 0x0b, 0x46, 0x08, 0x32,
	    0x32, 0x08, 0x46, 0x0b };
	//unsigned long uWinVersion = GetVersion();
	//sprintf(winVersion,"%u",uWinVersion);
	//EncodeVersion("HuaWei3COM1X", (unsigned char *)winVersion, 0x14);
	memcpy(buf + 24, winVersion, 20);
}

//Written By AGanNo2 (AGanNo2@163.com)
// use strConst to encrypt strDest
void HuaweiNetwork::EncodeVersion(const char *strConst, 
				      unsigned char *strDest, int iSize) {

	char *temp = new char[iSize];

	int iTimes = iSize / strlen(strConst);

	for (int i = 0; i < iTimes; i++)
	    memcpy(temp + i * strlen(strConst), strConst,
		   strlen(strConst));

	memcpy(temp + iTimes * strlen(strConst), strConst,
	       iSize % strlen(strConst));

	for (int i = 0; i < iSize; i++)
	    strDest[i] = strDest[i] ^ temp[i];

	for (int i = 0; i < iSize; i++)
	    strDest[iSize - i - 1] = strDest[iSize - i - 1] ^ temp[i];

	delete[]temp;
}
void HuaweiNetwork::Connected()
{
	system("/sbin/dhclient");
}
void HuaweiNetwork::message(const char *msg)
{
	cout << msg << endl;
}

// deal with the KeeponlineFrm

bool HuaweiNetwork::SendKeeponline(const u_char Id) {
	u_char buf[120] = { 0 };
	PKEEPONLINEFRM pbuf = (PKEEPONLINEFRM) buf;

	InitBuf(buf);
	pbuf->Hdr.Len1 = htons(strlen(m_Data.username) + 0x4e);
	pbuf->Hdr.Code = 0x02;
	pbuf->Hdr.Id = Id;
	pbuf->Hdr.Len2 = pbuf->Hdr.Len1;
	pbuf->Hdr.EapType = 0x14;
	pbuf->UseProxy = 0x00;
	pbuf->Unknown1[0] = 0x16;
	pbuf->Unknown1[1] = 0x20;
	memcpy(pbuf->Magic, m_Token, 32);
	pbuf->Unknown2[0] = 0x15;
	pbuf->Unknown2[1] = 0x04;
	if (m_Data.updateip == 0x01)
	    memcpy(pbuf->Ip, m_Data.ip, 4);
	memcpy(pbuf->Username, m_Data.username, strlen(m_Data.username));

	return !pcap_sendpacket(m_fp, buf, 64 + (int)strlen(m_Data.username));
}

bool HuaweiNetwork::GetToken(PTOKENFRM buf)
{
	PTOKENFRM pbuf = (PTOKENFRM)buf;
	//判断是否为所需数据包 0x23 0x44 0x23 0x31
	if(pbuf->Identifier[0] == 0x23 &&
		pbuf->Identifier[1] == 0x44 &&
		pbuf->Identifier[2] == 0x23 &&
		pbuf->Identifier[3] == 0x31)
	{
		memcpy(m_Token,pbuf->Token,33); //将服务器发来的Token串赋给m_Token
		m_Token[33] = 0;

		GenerateFinalMagic(m_Token);
		return true;
	}

	return false;
}

void HuaweiNetwork::GenerateMagic(u_char *buf)
{	//分四次进行生成Magic
	for(int i=0;i<4;i++)
	{
		CalcASC(buf + 8 * i);
	}
}

void HuaweiNetwork::GenerateFinalMagic(u_char *buf)
{
	GenerateMagic(buf);

	MD5_CTX md5T;
	//Magic的MD5值作为前16个字节
	md5T.MD5Update(m_Token,32);
	md5T.MD5Final(m_Token);
	m_Token[16] = 0;
	//再次MD5加密作为后16个字节
	md5T.MD5Update(m_Token,16);
	md5T.MD5Final(m_Token + 16);
}

void HuaweiNetwork::CalcASC(u_char *buf)
{	//H3C的算法，所得结果为ASCII字符串
	WORD Res;
	DWORD dEBX,dEBP;
	DWORD dEDX = 0x10;
	DWORD mSalt[4] = {0x56657824,0x56745632,0x97809879,0x65767878};

	DWORD dECX = *((DWORD*)buf);
	DWORD dEAX = *((DWORD*)(buf + 4));

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


	Res = LOWORD(dECX);
	*buf = LOBYTE(Res);
	*(buf+1) = HIBYTE(Res);

	Res = HIWORD(dECX);
	*(buf+2) = LOBYTE(Res);
	*(buf+3) = HIBYTE(Res);

	Res = LOWORD(dEAX);
	*(buf+4) = LOBYTE(Res);
	*(buf+5) = HIBYTE(Res);

	Res = HIWORD(dEAX);
	*(buf+6) = LOBYTE(Res);
	*(buf+7) = HIBYTE(Res);
}

}
