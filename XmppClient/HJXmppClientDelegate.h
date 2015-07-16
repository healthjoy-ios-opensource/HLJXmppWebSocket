//
//  HJXmppClientDelegate.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/8/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HJXmppClient;
@protocol XMPPMessageProto;


@protocol HJXmppClientDelegate <NSObject>

- (void)xmppClent:(id<HJXmppClient>)sender
didReceiveMessage:(id<XMPPMessageProto>)message
           atRoom:(NSString*)roomJid
         incoming:(BOOL)isMessageIncoming;


- (void)xmppClent:(id<HJXmppClient>)sender
didSendAttachmentTo:(NSString*)roomJid;

- (void)xmppClent:(id<HJXmppClient>)sender
didFailSendingAttachmentTo:(NSString*)roomJid
                 withError:(NSError*)error;


- (void)xmppClent:(id<HJXmppClient>)sender
didFailToReceiveMessageWithError:(NSError*)error;

- (void)xmppClent:(id<HJXmppClient>)sender
didSubscribeToRoom:(NSString*)roomJid;

- (void)xmppClentDidSubscribeToAllRooms:(id<HJXmppClient>)sender;

/**
 Actual messages will arrive in regular callbacks 
 
 * [HJXmppClientDelegate xmppClent:didReceiveMessage:]
 * [HJXmppClientDelegate xmppClent:didFailToReceiveMessageWithError:]
*/
- (void)xmppClent:(id<HJXmppClient>)sender
didLoadHistoryForRoom:(NSString*)roomJid
            error:(NSError*)maybeError;




// ???
- (void)xmppClent:(id<HJXmppClient>)sender
didFailSubscribingToRoom:(NSString*)roomJid
            error:(NSError*)error;



- (void)xmppClentDidCloseConnection:(id<HJXmppClient>)sender;
- (void)xmppClentDidAuthenticate:(id<HJXmppClient>)sender;

- (void)xmppClentDidFailToAuthenticate:(id<HJXmppClient>)sender
                                 error:(NSError*)error;


@end
