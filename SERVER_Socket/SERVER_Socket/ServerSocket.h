//
//  ServerSocket.h
//  Socket_Server
//
//  Created by Mia on 16/8/19.
//  Copyright © 2016年 Mia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerSocket : NSObject



/** 端口 */
@property (nonatomic,assign)uint16_t port;

/** 监听地址 */
@property (nonatomic,copy)NSString *listenURL;

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

@end
