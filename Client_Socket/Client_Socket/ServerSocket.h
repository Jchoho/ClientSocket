//
//  ServerSocket.h
//  Socket_Server
//
//  Created by Mia on 16/8/19.
//  Copyright © 2016年 Mia. All rights reserved.
//
@class GCDAsyncSocket;
#import <Foundation/Foundation.h>

#define ListenHost @"192.168.1.176"
#define ListenPost 8888

@protocol ServerSocketDelegate <NSObject>

-(void)ServerSocket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;


@end

@interface ServerSocket : NSObject



/** 端口 */
@property (nonatomic,assign)uint16_t port;

/** 监听地址 */
@property (nonatomic,copy)NSString *listenURL;

/** 代理 */
@property (nonatomic,weak)id<ServerSocketDelegate> delegate;

/**
 *  单例类方法
 *
 *  @return 单例对象
 */
+(instancetype)shareServerSocket;

/**
 *  开始监听
 */
-(void)startAccept;

/**
 *  停止监听
 */
-(void)stopAccpt;

@end
