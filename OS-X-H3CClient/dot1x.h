#ifndef		__DOT1X__H__
#define		__DOT1X__H__

#include "global.h"
#include <pcap/pcap.h>
#include <string>

namespace NetworkOperation {
using namespace std;
int GetSystemInterfaceInfo(InterfaceInfo * infoarray);

class HuaweiNetwork
{
	u_char m_DestMac[6];
	pcap_t *m_fp;		/* network interface device */
	USERDATA m_Data;	/* user data */
	bool isonline;
	bool isdaemon;		/* run as daemon */
	u_char m_Token[34];
//	int m_bDaemon;

	protected:
	void message(const char *msg);
//	void init_daemon();
	
	//void ConnectionInterrupted();

	char m_ClientVersion[14];
	bool SendVersion(const u_char Id);
	bool SendUsername(const u_char Id);
	bool SendPassword(const u_char Id, const u_char * Chap);
	bool SendKeeponline(const u_char Id);

	bool OpenAdapter();
	void CloseAdapter();

	void SetMd5Buf(PPASSWORDFRM pBuf, const u_char ID,
		       const u_char * chap);
	void InitBuf(u_char * buf);

	bool SendLogin();
	bool SendLogout();

	
	void GenerateVersion(u_char * buf);
	void EncodeVersion(const char *strConst, unsigned char *strDest,
			   int iSize);
  	public:
	HuaweiNetwork(const string &username, const string &passwd,
		       const string &interfacenum, int *ip, int *mac, int bRenew);

	//    virtual ~HuaweiNetwork();

	bool Connect();
	void DisConnect();
	void Connected();
	void run();

	private:
	bool GetToken(PTOKENFRM buf);
	void GenerateFinalMagic(u_char *buf);
	void GenerateMagic(u_char *buf);
	void CalcASC(u_char *buf);
};

}

#endif	//	__DOT1X__H__
