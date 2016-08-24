//
//  ServerSocket.m
//  Socket_Server
//
//  Created by Mia on 16/8/19.
//  Copyright © 2016年 Mia. All rights reserved.
//

#import "ServerSocket.h"
#import "GCDAsyncSocket.h"

@interface ServerSocket () <GCDAsyncSocketDelegate>


/** socket */
@property (nonatomic,strong)GCDAsyncSocket *socket;


/** 客户端socket数组 */
@property (nonatomic,strong)NSMutableArray *clientSockets;



@end

@implementation ServerSocket



-(NSMutableArray *)clientSockets{
    if (!_clientSockets) {
        _clientSockets = [NSMutableArray array];
    }
    return _clientSockets;
}

+(instancetype)shareServerSocket{
    static ServerSocket *serverSocket;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        serverSocket = [[self alloc]init];
    });
    return serverSocket;
}

-(instancetype)init{
    if (self = [super init]) {
        _socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    return self;
}

-(void)startAccept{
    NSError *error = nil;
    
    [self.socket acceptOnInterface:self.listenURL port:self.port error:&error];

    if (error) {
        NSLog(@"开启监听失败 : %@",error);
    }else{
        NSLog(@"开启监听成功");
    }
}

#pragma mark - GCDAsyncSocketDelegate

-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    
    //存放客户端的socket对象。
    [self.clientSockets addObject:newSocket];
    [newSocket readDataWithTimeout:-1 tag:0];
    
    //向每一个客户端发送给在线客户端列表
    [self sendClientList];
}



#pragma mark - GCDAsyncSocketDelegate
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{

    //每当有客户端断开连接的时候，客户端数组移除该socket
    [self.clientSockets removeObject:sock];
    
    //向每一个客户端发送给在线客户端列表
    [self sendClientList];
}



-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{

    [sock readDataWithTimeout:-1 tag:tag];

}

/**
 *  向每一个连接的客户端发送所有
 */
-(void)sendClientList{
    //把socket对象中的host和post转化成字符串，存放到数组中
    NSMutableArray *hostArrM = [NSMutableArray array];
    for (GCDAsyncSocket *clientSocket in self.clientSockets) {
        NSString *host_port = [NSString stringWithFormat:@"%@:%d",clientSocket.connectedHost,clientSocket.connectedPort];
        [hostArrM addObject:host_port];
    }
    
    //再把数组发送给每一个连接的客户端
    NSData *clientData = [NSKeyedArchiver archivedDataWithRootObject:hostArrM];
    
    for (GCDAsyncSocket *clientSocket in self.clientSockets) {
        [clientSocket writeData:clientData withTimeout:-1 tag:0];
    }
}

@end
