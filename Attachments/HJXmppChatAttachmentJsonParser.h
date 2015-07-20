//
//  HJXmppChatAttachmentJsonParser.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/20/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HJXmppChatAttachment;


@interface HJXmppChatAttachmentJsonParser : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

+ (id<HJXmppChatAttachment>)parseAttachmentResponse:(NSData*)input
                                              error:(NSError**)outError
__attribute__((nonnull));

@end
