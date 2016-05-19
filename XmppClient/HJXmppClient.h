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
@protocol HJChatButton;


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
- (void)loadHistoryFrom:(NSString *)createdAt to:(NSString *)closedAt forRoomJID:(NSString *)roomJID;


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
- (void)sendAttachments:(NSArray*)attachments
                    to:(NSString*)roomJid;


/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 */
- (void)selectOptionDirectiveForID:(NSString*)optionID
                             value:(NSString*)value
                                to:(NSString*)roomJid;

/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 */
- (void)selectSimpleOptionForID:(NSString*)optionID
                    value:(NSString*)value
                       to:(NSString*)roomJid;

/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 */
- (void)selectAutocompleteItemForID:(NSString*)itemID
                               name:(NSString*)name
                          messageID:(NSString*)messageID
                                 to:(NSString*)roomJid;

/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 */
- (void)sendPhoneNumber:(NSString*)phoneNumber
           phoneInputID:(NSString*)phoneInputID
                     to:(NSString*)roomJid;

/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 */
- (void)sendZip:(NSString*)zip
     zipInputID:(NSString*)zipInputID
             to:(NSString*)roomJid;

/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 */
- (void)sendDob:(NSString*)dob
     dobInputID:(NSString*)dobInputID
             to:(NSString*)roomJid;

/**
 @param roomJid One of values passed to the [HJXmppClient sendPresenseForRooms:] method. Should not contain any user id.
 '070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com'
 */
- (void)sendText:(NSString*)text
     textInputID:(NSString*)textInputID
             to:(NSString*)roomJid;

/**
 @param jid User id. Request for user/doctor/hcc avatar.
 hcc1.test+pha@xmpp-stage.healthjoy.com
 */
- (void)sendRequestAvatarForJid:(NSString *)jid;

/**
 @param jid User id. Request for user/doctor/hcc avatar.
 hcc1.test+pha@xmpp-stage.healthjoy.com
 */
- (void)sendReadReceiptForID:(NSString *)identification
                          to:(NSString *)roomJid;

- (void)disconnect;

/**
 Typically a weak property
 */
- (id<HJXmppClientDelegate>)listenerDelegate;
- (void)setListenerDelegate:(id<HJXmppClientDelegate>)value;

@end
