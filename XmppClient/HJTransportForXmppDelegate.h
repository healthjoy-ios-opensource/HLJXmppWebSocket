//
//  HJTransportForXmppDelegate.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/9/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HJTransportForXmpp;

@protocol HJTransportForXmppDelegate <NSObject>

- (void)transportDidOpenConnection:(id<HJTransportForXmpp>)webSocket;

- (void)transportDidFailToOpenConnection:(id<HJTransportForXmpp>)webSocket
                               withError:(NSError*)error;

- (void)transport:(id<HJTransportForXmpp>)webSocket
didReceiveMessage:(id)message;

- (void)transport:(id<HJTransportForXmpp>)webSocket
didFailToReceiveMessageWithError:(NSError*)error;

- (void)transportDidCloseConnection:(id<HJTransportForXmpp>)webSocket
                               code:(NSInteger)code
                             reason:(NSString *)reason;

@end
