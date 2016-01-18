//
//  HJChatHistoryRequestBuilder.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/14/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HJRandomizerForXmpp;
@protocol HJChatHistoryRequestProto;

@interface HJChatHistoryRequestBuilder : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithRandomizer:(id<HJRandomizerForXmpp>)randomizer
NS_REQUIRES_SUPER
NS_DESIGNATED_INITIALIZER
__attribute__((nonnull));

- (id<HJChatHistoryRequestProto>)buildRequestFrom:(NSString *)createdAt
                                               to:(NSString *)closedAt
                                       forRoomJID:(NSString *)roomJID;

@end
