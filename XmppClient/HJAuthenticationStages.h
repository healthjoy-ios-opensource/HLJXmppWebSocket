//
//  HJAuthenticationStages.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/9/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HJAuthenticationStages)
{
    XMPP_PLAIN_AUTH__NOT_STARTED = 0,
    XMPP_PLAIN_AUTH__READY_FOR_AUTH_REQUEST   ,
    XMPP_PLAIN_AUTH__AUTH_REQUEST_COMPLETED   ,
    XMPP_PLAIN_AUTH__READY_FOR_BIND_REQUEST   ,
    XMPP_PLAIN_AUTH__READY_FOR_SESSION_REQUEST,
    XMPP_PLAIN_AUTH__COMPLETED,
    XMPP_PLAIN_AUTH__FAILED,
    XMPP_PLAIN_AUTH__CONNECTION_CLOSED
};
