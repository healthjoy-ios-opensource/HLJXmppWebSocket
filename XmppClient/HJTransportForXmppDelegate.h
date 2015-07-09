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

- (void)transport:(id<HJTransportForXmpp>)webSocket
didReceiveMessage:(id)message;

@end
