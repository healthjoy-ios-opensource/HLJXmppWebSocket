//
//  HJChatHistoryRequest.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/15/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJChatHistoryRequestProto.h"

@interface HJChatHistoryRequest : NSObject<HJChatHistoryRequestProto>

@property (nonatomic, copy) NSString* idForIq   ;
@property (nonatomic, copy) NSString* idForQuery;
@property (nonatomic, copy) NSString* dataToSend;

@end
