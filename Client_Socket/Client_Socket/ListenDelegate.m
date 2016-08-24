//
//  ListenDelegate.m
//  Client_Socket
//
//  Created by Mia on 16/8/19.
//  Copyright © 2016年 Mia. All rights reserved.
//

#import "ListenDelegate.h"
#import <GCDAsyncSocket.h>

@interface ListenDelegate ()

@end

@implementation ListenDelegate


-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
  
}

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"客户端与客户端连接成功");
    [sock readDataWithTimeout:-1 tag:0 ];
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"客户端与客户端连接失败 error:%@",err);
}

@end
