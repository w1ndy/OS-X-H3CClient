//
//  H3CClientConnector.h
//  OS-X-H3CClient
//
//  Created by Arthas on 6/6/14.
//  Copyright (c) 2014 Shandong University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface H3CClientConnector : NSObject

- (id)init;

- (BOOL)openAdapter:(NSString *)interfaceName;
- (void)closeAdapter;

@end
