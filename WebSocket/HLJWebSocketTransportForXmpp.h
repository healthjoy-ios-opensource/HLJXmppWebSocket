//
//  HLJWebSocketTransportForXmpp.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/10/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HLJXmppWebSocket/XmppClient/HJTransportForXmpp.h>

@protocol HJTransportForXmppDelegate;
@class SRWebSocket;

@interface HLJWebSocketTransportForXmpp : NSObject<HJTransportForXmpp>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new  NS_UNAVAILABLE;

- (instancetype)initWithWebSocket:(SRWebSocket*)webSocket
NS_DESIGNATED_INITIALIZER
NS_REQUIRES_SUPER
__attribute__((nonnull));

@property (nonatomic, weak) id<HJTransportForXmppDelegate> delegate;

@end
