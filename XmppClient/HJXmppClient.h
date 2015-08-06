//
//  HJXmppClient.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/8/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIImage;
@protocol HJTransportForXmpp;
@protocol HJXmppClientDelegate;


@protocol HJXmppClient <NSObject>

/**
 Both the web socket is connected and the authentication has passed.
 */
- (BOOL)isOnline;

/**
 Performs PLAIN authentication only.
 
 Note : this method is used for the hot fix. If you are going to send/receive messages, please use [HJXmppClient sendPresenseForRooms:] instead.
 */
- (void)authenticateAsync;

/**
 Performs PLAIN authentication as well
 
 @param jidStringsForRooms JID items in NSString representation
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)'
 
 This method should be invoked only once. Please create a new connection if you need subscribing to one more room.
 */
- (void)sendPresenseForRooms:(NSArray*)jidStringsForRooms;

/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 
  Note : Latest messages arrive first
 */
- (void)loadHistoryForRoom:(NSString*)roomJid;


/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 
 @param maxMessageCount Limit of messages returned in response. 
 
 Note : Latest messages arrive first
 */
- (void)loadHistoryForRoom:(NSString*)roomJid
                     limit:(NSUInteger)maxMessageCount;

/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 */
- (void)sendMessage:(NSString*)messageFromUser
                 to:(NSString*)roomJid;

/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 */
- (void)sendAttachment:(UIImage*)attachment
                    to:(NSString*)roomJid;

- (void)disconnect;

/**
 Typically a weak property
 */
- (id<HJXmppClientDelegate>)listenerDelegate;
- (void)setListenerDelegate:(id<HJXmppClientDelegate>)value;

@end
