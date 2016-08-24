//
//  ViewController.m
//  Client_Socket
//
//  Created by Mia on 16/8/19.
//  Copyright © 2016年 Mia. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "ServerSocket.h"
#import "ListenDelegate.h"
#import "MyTableViewCell.h"

@interface ViewController ()<GCDAsyncSocketDelegate,UITableViewDelegate,UITableViewDataSource,ServerSocketDelegate>


@property (weak, nonatomic) IBOutlet UITextField *inputTextField;
@property (weak, nonatomic) IBOutlet UITextField *serverHost;
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;
@property (weak, nonatomic) IBOutlet UIButton *disConnect;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *receiveDataLabel;

/** tableView数据 数组 */
@property (nonatomic,strong)NSMutableArray *dataSoures;

/** client_socket */
@property (nonatomic,strong)GCDAsyncSocket *client_socket;

/** 个人聊天socket字典 */
@property (nonatomic,strong)NSMutableDictionary *mySocketsDict;

/** 自身监听socket */
@property (nonatomic,strong)ServerSocket *listenSocket;

/** 当前活跃的socket */
@property (nonatomic,strong)GCDAsyncSocket *activeSocket;

/** 自身监听socket的代理 */
@property (nonatomic,strong)ListenDelegate *ltnDelegate;

@end

@implementation ViewController

-(NSMutableDictionary *)mySocketsDict{
    if (!_mySocketsDict.count) {
        _mySocketsDict = [NSMutableDictionary dictionary];
    }
    return _mySocketsDict;
}

- (IBAction)sendClick:(UIButton *)sender {
    NSString *sendStr = self.inputTextField.text;
    //根据当前选中的客户端socket来发送消息
    [self.activeSocket writeData:[sendStr dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:321];
}

/**
 *  点击断开连接时候，需要清空连接公共服务器的socket，清空当前选中socket，清空自身保存其他客户端连接socket的字典，关闭自身在监听的服务
 *
 *  @param sender
 */
- (IBAction)disConnectClick:(UIButton *)sender {
    [_client_socket disconnect];
    self.connectBtn.enabled = YES;
    
    self.activeSocket = nil;
    [self.mySocketsDict removeAllObjects];
    self.mySocketsDict = nil;
    
    [self.listenSocket stopAccpt];
    self.listenSocket = nil;
}

/**
 *  点击连接按钮时，需要连接到公共服务器，然后在成功连接的方法回调时候，开启自身的监听
 *
 *  @param sender
 */
- (IBAction)connectClick:(UIButton *)sender {
    NSError *error = nil;
    [_client_socket connectToHost:self.serverHost.text onPort:8888 error:&error];
    
    NSLog(@"%@",error);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _client_socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    UILabel *headerLabel = [[UILabel alloc]init];
    headerLabel.text = @"点击IP发送信息";
    headerLabel.frame = CGRectMake(0, 0, 100, 20);
    self.tableView.tableHeaderView = headerLabel;
    self.tableView.sectionHeaderHeight = 20;
    self.tableView.backgroundColor = [UIColor lightGrayColor];

}

#pragma mark - GCDAsyncSocketDelegate
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    NSArray *clientOnLine = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    //根据最新的在线列表来删除自身在线列表字典已经下线的客户端
    NSMutableArray *deleteKeys = [self.dataSoures mutableCopy];
    [deleteKeys removeObjectsInArray:clientOnLine];

    for (NSString * key in deleteKeys) {
        [self.mySocketsDict removeObjectForKey:key];
    }

    //获取最新的客户端在线列表
    self.dataSoures = [clientOnLine mutableCopy];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    
    [sock readDataWithTimeout:-1 tag:0];
    
}


-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"连接成功");
    //更新选中的socket
    self.activeSocket = sock;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.connectBtn.enabled = NO;
        self.disConnect.enabled = YES;
    });
    
    //开启自身的监听
    ServerSocket *listenSocket = [ServerSocket shareServerSocket];
    listenSocket.port = sock.localPort;
    listenSocket.listenURL = ListenHost;
    self.listenSocket = listenSocket;
    self.listenSocket.delegate = self;
    [listenSocket startAccept];
    
    
    [sock readDataWithTimeout:-1 tag:0];
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    
    //断开连接时，清空数据源
    [self.dataSoures removeAllObjects];

    dispatch_sync(dispatch_get_main_queue(), ^{
        self.connectBtn.enabled = YES;
        self.disConnect.enabled = NO;
        [self.tableView reloadData];
    });
    
}



#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSoures.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString * cellID = @"cellID";
    MyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[MyTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    if (self.dataSoures.count) {
        cell.textLabel.text = self.dataSoures[indexPath.row];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    ListenDelegate *ltnDelegate = [[ListenDelegate alloc]init];
    self.ltnDelegate = ltnDelegate;
    
    //根据选中的客户端进行长连接
    //查看已经保存的其他客户端列表字段中是否已经存在相应的socket
    NSString *hostStr = self.dataSoures[indexPath.row];
    GCDAsyncSocket *activeSocket = self.mySocketsDict[hostStr];
    
    //如果字典中没有对应的socket,则创建新的socket,并且存进字段
    if (!activeSocket) {
        activeSocket = [[GCDAsyncSocket alloc]initWithDelegate:ltnDelegate delegateQueue:dispatch_get_global_queue(0, 0)];
        self.mySocketsDict[hostStr] = activeSocket;
    }
    
    //更新选中的socket
    self.activeSocket = activeSocket;
    
    //行进socket连接
    NSArray *arr = [hostStr componentsSeparatedByString:@":"];

    NSError *error = nil;

    NSString *portStr = arr[1];
    
    [activeSocket connectToHost:arr[0] onPort:portStr.integerValue error:&error];
    
}


#pragma mark ServerSocketDelegate

-(void)ServerSocket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //接受其他客户端发送的消息，并且显示
    NSString *receiveStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSString *resultStr = [NSString stringWithFormat:@"%@\n%@",self.receiveDataLabel.text,receiveStr] ;
        self.receiveDataLabel.text = resultStr;
    });
    
}



@end
