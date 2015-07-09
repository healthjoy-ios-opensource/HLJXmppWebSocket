//
//  HJXmppClientImpl.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/9/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJXmppClientImpl.h"

#import "HJTransportForXmpp.h"
#import "HJTransportForXmppDelegate.h"

#import "HJAuthenticationStages.h"

#import <XmppFrameworkParsers/XmppFrameworkParsers.h>

@interface HJXmppClientImpl() <XMPPParserDelegate, HJTransportForXmppDelegate>
@end


@implementation HJXmppClientImpl
{
    id<HJTransportForXmpp> _transport            ;
    id<XMPPParserProto>    _xmppParser           ;
    NSString*              _xmppHost             ;
    NSString*              _accessToken          ;
    NSString*              _jidStringFromUserInfo;
    
    HJAuthenticationStages _authStage;
}

- (instancetype)initWithTransport:(id<HJTransportForXmpp>)transport
                       xmppParser:(id<XMPPParserProto>)xmppParser
                             host:(NSString*)host
                      accessToken:(NSString*)accessToken
                    userJidString:(NSString*)jidString {

    NSParameterAssert(nil != transport);
    NSParameterAssert(nil != host);
    NSParameterAssert(nil != accessToken);
    NSParameterAssert(nil != jidString);
    
    self = [super init];
    if (nil == self) {
        
        return nil;
    }
    
    self->_authStage = XMPP_PLAIN_AUTH__NOT_STARTED;
    
    self->_transport             = transport  ;
    [self->_transport setDelegate: self];
    
    
    // TODO : change later
    dispatch_queue_t parserCallbacksQueue = dispatch_get_main_queue();
    self->_xmppParser = xmppParser;
    [self->_xmppParser setDelegate: self
                     delegateQueue: parserCallbacksQueue];
    
    self->_xmppHost              = host       ;
    self->_accessToken           = accessToken;
    self->_jidStringFromUserInfo = jidString  ;
    
    return self;
}

- (void)sendPresenseForRooms:(NSArray*)jidStringsForRooms {
    
    [self doPerformPlainAuthentication];
    
    NSAssert(NO, @"not implemented");
}

- (void)doPerformPlainAuthentication {

    
    static NSString* messageFormat = @"<open xmlns='urn:ietf:params:xml:ns:xmpp-framing' to='%@' version='1.0'/>";
    NSString* message = [NSString stringWithFormat: messageFormat, self->_xmppHost];
    
    
    [self->_transport send: message];
}



- (void)sendMessage:(id)messageFromUser {
    
    NSParameterAssert(XMPP_PLAIN_AUTH__COMPLETED == self->_authStage);
    
    NSAssert(NO, @"not implemented");
}

- (void)sendAttachment:(NSData*)binaryFromUser {
    
    NSParameterAssert(XMPP_PLAIN_AUTH__COMPLETED == self->_authStage);
    
    NSAssert(NO, @"not implemented");
}

#pragma mark - HJTransportForXmppDelegate
- (void)transport:(id<HJTransportForXmpp>)webSocket
didReceiveMessage:(id)rawMessage
{
    NSData* rawMessageData = nil;
    if ([rawMessage isKindOfClass: [NSData class]])
    {
        rawMessageData = (NSData*)rawMessage;
    }
    else if ([rawMessage isKindOfClass: [NSString class]])
    {
        NSString* strRawMessage = (NSString*)rawMessage;
        rawMessageData = [strRawMessage dataUsingEncoding: NSUTF8StringEncoding];
    }
    else
    {
        NSAssert(NO, @"Unknown transport response object");
    }
    
    
    [self->_xmppParser parseData: rawMessageData];
}


#pragma mark - XMPPParserDelegate
- (void)xmppParser:(XMPPParser *)sender
    didReadElement:(NSXMLElement *)element {
    
    
    
}

@end
