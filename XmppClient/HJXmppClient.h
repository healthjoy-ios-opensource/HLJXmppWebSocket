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
 Performs PLAIN authentication as well
 
 @param jidStringsForRooms JID items in NSString representation
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)'
 
 This method should be invoked only once. Please create a new connection if you need subscribing to one more room.
 */
- (void)sendPresenseForRooms:(NSArray*)jidStringsForRooms;

/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 */
- (void)loadHistoryForRoom:(NSString*)roomJid;

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
