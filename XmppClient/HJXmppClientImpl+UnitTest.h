//
//  HJXmppClientImpl+UnitTest.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/15/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJXmppClientImpl.h"

@protocol XMPPMessageProto;


@interface HJXmppClientImpl (UnitTest)

@property (nonatomic, readonly) NSString* jidStringFromBind;
- (BOOL)isMessageIncoming:(id<XMPPMessageProto>)element;

@end
