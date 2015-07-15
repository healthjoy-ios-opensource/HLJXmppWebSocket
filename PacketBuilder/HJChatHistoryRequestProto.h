//
//  HJChatHistoryRequestProto.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/15/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HJChatHistoryRequestProto <NSObject>

- (NSString*)idForIq;
- (NSString*)idForQuery;
- (NSString*)dataToSend;

@end
