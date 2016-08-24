//
//  main.m
//  SERVER_Socket
//
//  Created by Mia on 16/8/19.
//  Copyright © 2016年 Mia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerSocket.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        ServerSocket *serverSocket = [ServerSocket shareServerSocket];
        serverSocket.port = 8888;
        
#warning 注意改为自己本机的IP
        //注意改为自己本机的IP
        serverSocket.listenURL = @"192.168.1.176";        
        [serverSocket startAccept];
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}
