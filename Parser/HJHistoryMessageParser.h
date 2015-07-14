//
//  HJHistoryMessageParser.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XMPPMessageProto;

@interface HJHistoryMessageParser : NSObject

+ (id<XMPPMessageProto>)unwrapHistoryMessage:(id<XMPPMessageProto>)element;

@end
