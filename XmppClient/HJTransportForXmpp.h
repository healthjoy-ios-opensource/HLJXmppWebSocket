//
//  HJTransportForXmpp.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/9/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HJTransportForXmppDelegate;

/**
 Same as SRWebSocketProtocol
 */
@protocol HJTransportForXmpp <NSObject>

- (void)open;

- (void)close;
- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;

// Send a UTF8 String or Data.
- (void)send:(id)data;

- (id<HJTransportForXmppDelegate>)delegate;
- (void)setDelegate:(id<HJTransportForXmppDelegate>)delegate;

@end
