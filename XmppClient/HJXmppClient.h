//
//  HJXmppClient.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/8/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HJTransportForXmpp;
@protocol HJXmppClientDelegate;


@protocol HJXmppClient <NSObject>

/**
 Performs PLAIN authentication as well
 
 @param jidStringsForRooms JID items in NSString representation
 */
- (void)sendPresenseForRooms:(NSArray*)jidStringsForRooms;

- (void)sendMessage:(id)messageFromUser;
- (void)sendAttachment:(NSData*)binaryFromUser;


/**
 Typically a weak property
 */
- (id<HJXmppClientDelegate>)listenerDelegate;
- (void)setListenerDelegate:(id<HJXmppClientDelegate>)value;

@end
