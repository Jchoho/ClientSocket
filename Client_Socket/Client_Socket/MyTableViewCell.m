//
//  MyTableViewCell.m
//  Client_Socket
//
//  Created by Mia on 16/8/24.
//  Copyright © 2016年 Mia. All rights reserved.
//

#import "MyTableViewCell.h"

@implementation MyTableViewCell

-(void)setFrame:(CGRect)frame{
    CGRect rect = frame;
    rect.origin.x = frame.origin.x + 10;
    rect.origin.y = frame.origin.y + 1;
    rect.size.width = frame.size.width - 20;
    rect.size.height = frame.size.height - 2;
    frame = rect;
    [super setFrame:frame];
}

@end
