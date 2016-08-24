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

-(void)startAccept{
    NSError *error = nil;
    @synchronized (self) {
        self.socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
        [self.socket acceptOnInterface:self.listenURL port:self.port error:&error];
    }
    if (error) {
        NSLog(@"开启监听失败 : %@",error);
    }else{
        NSLog(@"listenURL:%@,port:%d",self.listenURL,self.port);
        NSLog(@"开启监听成功");
    }
}

-(void)stopAccpt{
    @synchronized (self) {
        self.socket = nil;
        [self.clientSockets removeAllObjects];
    }
}

#pragma mark - GCDAsyncSocketDelegate

-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{

    [self.clientSockets addObject:newSocket];
    [newSocket readDataWithTimeout:-1 tag:0];
    
//    [self sendClientList];

}


-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    
    if (self.socket) {
        [self.clientSockets removeObject:sock];
//        [self sendClientList];
    }
    
}



-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    [sock readDataWithTimeout:-1 tag:0];
    
    if ([self.delegate respondsToSelector:@selector(ServerSocket:didReadData:withTag:)]) {
        [self.delegate ServerSocket:sock didReadData:data withTag:tag];
    }
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
