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
#import "HJXmppClientDelegate.h"

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
    
    BOOL _isStreamResponseReceived;
    BOOL _isStreamFeaturesResponseReceived;
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

    [self sendStreamRequest];
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
    
    // Assuming "parseData:" is reenterable
    [self->_xmppParser parseData: rawMessageData];
}


#pragma mark - XMPPParserDelegate
- (void)xmppParser:(id<XMPPParserProto>)sender
    didReadElement:(NSXMLElement *)element {
    
    // TODO : use TransitionKit or other state machine
    // https://github.com/blakewatters/TransitionKit
    switch (self->_authStage)
    {
        case XMPP_PLAIN_AUTH__NOT_STARTED:
        {
            [self handleAuthStreamOpenResponse: element];
            break;
        }
        case XMPP_PLAIN_AUTH__READY_FOR_AUTH_REQUEST:
        {
            [self handleAuthResponse: element];
            break;
        }
        case XMPP_PLAIN_AUTH__AUTH_REQUEST_COMPLETED:
        {
            [self checkForSecondStreamResponse: element];
            break;
        }
            
        case XMPP_PLAIN_AUTH__COMPLETED:
        {
            [self handlePresenseOrMessageElement: element];
            break;
        }
            
        case XMPP_PLAIN_AUTH__FAILED:
        default:
        {
            // IDLE
            break;
        }

    }
    
}


- (void)sendStreamRequest
{
    static NSString* messageFormat = @"<open xmlns='urn:ietf:params:xml:ns:xmpp-framing' to='%@' version='1.0'/>";
    NSString* message = [NSString stringWithFormat: messageFormat, self->_xmppHost];
    
    
    [self->_transport send: message];
}



#pragma mark - auth stream
- (void)handleAuthStreamOpenResponse:(NSXMLElement *)element {
    
    BOOL isStreamResponse = [[element name] isEqualToString: @"stream:features"];

    if (isStreamResponse)
    {
        if (![self isPlainAuthInStreamFeatures: element])
        {
            self->_authStage = XMPP_PLAIN_AUTH__FAILED;
            
            // TODO : extract error class
            NSError* error = [NSError errorWithDomain: @"xmpp.websocket"
                                                 code: 1
                                             userInfo: nil];
            
            id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
            [strongDelegate xmppClentDidFailToAuthenticate: self
                                                     error: error];
        }
        else
        {
            self->_authStage = XMPP_PLAIN_AUTH__READY_FOR_AUTH_REQUEST;
            [self sendAuthRequest];
        }
    }
    else
    {
        // IDLE
    }
}

- (BOOL)isPlainAuthInStreamFeatures:(NSXMLElement *)element {
    
//    <stream:features
//    xmlns="jabber:client"
//xmlns:stream="http://etherx.jabber.org/streams"
//    version="1.0">
//    
//    <mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl">
//    <mechanism>PLAIN</mechanism>
//    </mechanisms>
//    
//    <c
//    xmlns="http://jabber.org/protocol/caps"
//    hash="sha-1"
//    node="http://www.process-one.net/en/ejabberd/"
//    ver="6LZsyp9FYXV9NHsBmxJvPrDLTQs="/>
//    
//    <register xmlns="http://jabber.org/features/iq-register"/>
//    </stream:features>

    NSError* xpathError = nil;
    NSArray* authMechanismNodes =
    [element nodesForXPath: @"stream:features/mechanisms/mechanism[text()='PLAIN']"
                     error: &xpathError];
    
    if (0 == [authMechanismNodes count]) {
        return NO;
    }
    
    return YES;
}


#pragma mark - send request
- (void)sendAuthRequest {

    static NSString* const messageFormat =
    @"<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>%@</auth>";
    NSString* message = [NSString stringWithFormat: messageFormat, self->_accessToken];
    
    [self->_transport send: message];

}

- (void)sendBindRequest {
    
//    <iq type='set' id='_bind_auth_2' xmlns='jabber:client'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'/></iq>
    
//    <iq id="_bind_auth_2" type="result" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user+11952@xmpp-dev.healthjoy.com/21566872121436444488218507</jid></bind></iq>
    
}


// === session_auth_2
//<iq type='set' id='_session_auth_2' xmlns='jabber:client'><session xmlns='urn:ietf:params:xml:ns:xmpp-session'/></iq>

//<iq type="result" xmlns="jabber:client" id="_session_auth_2" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"/>


#pragma mark - auth
- (void)handleAuthResponse:(NSXMLElement *)element {

    BOOL isSuccess = [[element name] isEqualToString: @"success"];
    if (isSuccess)
    {
        self->_authStage = XMPP_PLAIN_AUTH__AUTH_REQUEST_COMPLETED;
        [self sendStreamRequest];
    }
    else
    {
        self->_authStage = XMPP_PLAIN_AUTH__FAILED;
    }
}


- (void)checkForSecondStreamResponse:(NSXMLElement *)element {
    
    if ([[element name] isEqualToString: @"stream:stream"])
    {
        //    <stream:stream xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" id="3277139085" from="xmpp-dev.healthjoy.com" version="1.0" xml:lang="en"/>

        
        self->_isStreamResponseReceived = YES;
    }
    if ([[element name] isEqualToString: @"stream:features"])
    {
        //    <stream:features xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/><session xmlns="urn:ietf:params:xml:ns:xmpp-session"/><sm xmlns="urn:xmpp:sm:2"/><sm xmlns="urn:xmpp:sm:3"/><c xmlns="http://jabber.org/protocol/caps" hash="sha-1" node="http://www.process-one.net/en/ejabberd/" ver="6LZsyp9FYXV9NHsBmxJvPrDLTQs="/><register xmlns="http://jabber.org/features/iq-register"/></stream:features>

        
        self->_isStreamFeaturesResponseReceived = YES;
    }
    
    

    if (self->_isStreamResponseReceived && self->_isStreamFeaturesResponseReceived)
    {
        self->_authStage = XMPP_PLAIN_AUTH__READY_FOR_BIND_REQUEST;
        [self sendBindRequest];
    }
}

#pragma mark - Messages
- (void)handlePresenseOrMessageElement:(NSXMLElement *)element {
}

@end
