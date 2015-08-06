//
//  HLJWebSocketTransportForXmpp.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/10/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HLJWebSocketTransportForXmpp.h"

#import "HJTransportForXmppDelegate.h"


@interface HLJWebSocketTransportForXmpp()<SRWebSocketDelegate>
@end


@implementation HLJWebSocketTransportForXmpp
{
    id<SRWebSocketProtocol> _webSocket;
}

- (instancetype)initWithWebSocket:(id<SRWebSocketProtocol>)webSocket {
    
    self = [super init];
    if (nil == self) {
        
        return nil;
    }
    
    self->_webSocket = webSocket;
    [self->_webSocket setDelegate: self];
    
    return self;
}


- (NSInteger)readyState
{
    return [self->_webSocket readyState];
}

- (void)open {
    
    [self->_webSocket open];
}

- (void)close {
    
    [self->_webSocket close];
}

- (void)closeWithCode:(NSInteger)code
               reason:(NSString *)reason {
    
    [self->_webSocket closeWithCode: code
                             reason: reason];
}

// Send a UTF8 String or Data.
- (void)send:(id)data {
    
    [self->_webSocket send: data];
}


#pragma mark - SRWebSocketDelegate
- (void)webSocket:(SRWebSocket *)webSocket
didReceiveMessage:(id)message
{
    id<HJTransportForXmppDelegate> strongDelegate = self.delegate;
    [strongDelegate transport: self
            didReceiveMessage: message];
    
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {

    id<HJTransportForXmppDelegate> strongDelegate = self.delegate;
    [strongDelegate transportDidOpenConnection: self];
}


- (void)webSocket:(SRWebSocket *)webSocket
 didFailWithError:(NSError *)error
{
    id<HJTransportForXmppDelegate> strongDelegate = self.delegate;
    [strongDelegate transport: self didFailToReceiveMessageWithError: error];
}

- (void)webSocket:(SRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean
{
    id<HJTransportForXmppDelegate> strongDelegate = self.delegate;
    [strongDelegate transportDidCloseConnection: self];
}

- (void)webSocket:(SRWebSocket *)webSocket
   didReceivePong:(NSData *)pongPayload
{
    // IDLE
}


@end
