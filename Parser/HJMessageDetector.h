//
//  HJMessageDetector.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XMPPMessageProto;

@interface HJMessageDetector : NSObject

+ (BOOL)isFinMessage:(id<XMPPMessageProto>)element;
+ (BOOL)isHistoryMessage:(id<XMPPMessageProto>)element;
+ (BOOL)isCloseChatMessage:(id<XMPPMessageProto>)element;

@end
