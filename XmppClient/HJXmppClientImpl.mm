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
#import "HJChatHistoryRequestBuilder.h"
#import "HJRandomizerImpl.h"

#import "HJXmppErrorForHistory.h"
#import "HJXmppBindParserError.h"
#import "HJXmppSessionResponseError.h"

#import "HJBindResponseParser.h"
#import "HJSessionResponseParser.h"
#import "HJHistoryFailParser.h"


#define NSLog(...)

typedef std::set< __strong id<XMPPParserProto> > XmppParsersSet;
typedef std::map< __strong id<XMPPParserProto>, __strong NSXMLElement* > StanzaRootForParserMap;

@interface HJXmppClientImpl() <XMPPParserDelegate, HJTransportForXmppDelegate>
@end


@implementation HJXmppClientImpl
{
    id<HJTransportForXmpp> _transport            ;
    XmppParserBuilderBlock _xmppParserFactory    ;
    XmppParsersSet         _parsers              ;
    StanzaRootForParserMap _rootNodeForParser    ;
    
    NSString*              _xmppHost             ;
    NSString*              _accessToken          ;
    NSArray *              _jidStringsForRooms   ;
    
    NSMutableSet*          _pendingRooms;
    
    
    NSString*              _jidStringFromUserInfo;
    NSString*              _jidStringFromBind    ;

    
    
    HJAuthenticationStages _authStage                       ;
    BOOL                   _isStreamResponseReceived        ;
    BOOL                   _isStreamFeaturesResponseReceived;
    
    
    // TODO : use dependency injection
    HJChatHistoryRequestBuilder* _historyRequestBuilder;
    HJRandomizerImpl           * _randomizerForHistoryBuilder;
}

- (void)dealloc {
    
    [self disconnect];
}

- (void)disconnect {
    
    [self->_transport close];
}

- (dispatch_queue_t)parserCallbacksQueue {
    
    // TODO : change for production if needed
    
    dispatch_queue_t parserCallbacksQueue = dispatch_get_main_queue();
    return parserCallbacksQueue;
}

- (instancetype)initWithTransport:(id<HJTransportForXmpp>)transport
                xmppParserFactory:(XmppParserBuilderBlock)xmppParserFactory
                             host:(NSString*)host
                      accessToken:(NSString*)accessToken
                    userJidString:(NSString*)jidString {

    NSParameterAssert(nil != transport);
    NSParameterAssert(nil != xmppParserFactory);
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
    
    self->_xmppParserFactory = [xmppParserFactory copy];
    
    self->_xmppHost              = host       ;
    self->_accessToken           = accessToken;
    
    self->_jidStringFromUserInfo = jidString  ;
    
    {
        self->_randomizerForHistoryBuilder = [HJRandomizerImpl new];
        self->_historyRequestBuilder = [[HJChatHistoryRequestBuilder alloc] initWithRandomizer: self->_randomizerForHistoryBuilder];
    }
    
    return self;
}

- (void)sendPresenseForRooms:(NSArray*)jidStringsForRooms {
    
    NSParameterAssert(nil == self->_jidStringsForRooms);

    
    self->_jidStringsForRooms = jidStringsForRooms;
    [self->_transport open];
}

- (void)doPerformPlainAuthentication {

    // the callbacks will send the presense stanza
    [self sendStreamRequest];
}

- (void)doSendPresenseRequests {
    
//    <presence
//    from='user+11952@xmpp-dev.healthjoy.com/42306807851436517615666295'
//    to='070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)'
//    xmlns='jabber:client'>
//    <x
//    xmlns='http://jabber.org/protocol/muc'/>
//    </presence>

    
    static NSString* const presenseRequestFormat =
        @"<presence \n"
        @"\t from='%@' \n"
        @"\t to='%@'   \n"
        @"\t xmlns='jabber:client'> \n"
        @"\t\t <x \n"
        @"\t\t\t\t xmlns='http://jabber.org/protocol/muc'/> \n"
        @"</presence>";

    
    LINQSelector jidToPresenseRequest = ^NSString*(NSString* jidItem)
    {
        NSString* presenseRequest =
            [NSString stringWithFormat:
                 presenseRequestFormat,
                 self->_jidStringFromBind,
                 jidItem];
        
        return presenseRequest;
    };
    NSArray* presenseRequests = [self->_jidStringsForRooms linq_select: jidToPresenseRequest];
    
    
    self->_pendingRooms = [NSMutableSet setWithArray: self->_jidStringsForRooms];
    for (NSString* singlePresenseRequest in presenseRequests)
    {
        [self->_transport send: singlePresenseRequest];
    }
}

- (void)sendMessage:(id)messageFromUser {
    
    NSParameterAssert(XMPP_PLAIN_AUTH__COMPLETED == self->_authStage);
    
    NSAssert(NO, @"not implemented");
}

- (void)sendAttachment:(NSData*)binaryFromUser {
    
    NSParameterAssert(XMPP_PLAIN_AUTH__COMPLETED == self->_authStage);
    
    NSAssert(NO, @"not implemented");
}

- (void)loadHistoryForRoom:(NSString*)roomJid {
    
    LINQSelector truncatedRoomId = ^NSString*(NSString* fullRoomString)
    {
        //    [presense] - 070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)
        //    [iq      ] - 070815_114612_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com

        
        NSArray* chunks = [fullRoomString componentsSeparatedByString: @"/"];
        NSString* blockResult = [chunks firstObject];
        
        return blockResult;
    };
    NSArray* multipleRoomIdForHistory = [self->_jidStringsForRooms linq_select: truncatedRoomId];
    BOOL isRoomOnTheList = (0 != [multipleRoomIdForHistory count]);
    
    if (!isRoomOnTheList)
    {
        NSParameterAssert([multipleRoomIdForHistory containsObject: roomJid]);
        return;
    }

    
    NSString* request = [self->_historyRequestBuilder buildRequestForRoom: roomJid];
    [self->_transport send: request];
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
    
    // "parseData:" is NOT reenterable
    // https://github.com/robbiehanson/XMPPFramework/issues/560
    dispatch_queue_t parserCallbacksQueue = [self parserCallbacksQueue];

    id<XMPPParserProto> parser = self->_xmppParserFactory();
    [parser setDelegate: self
          delegateQueue: parserCallbacksQueue];
    self->_parsers.insert(parser);

    [parser parseData: rawMessageData];
}

- (void)transportDidOpenConnection:(id<HJTransportForXmpp>)webSocket
{
    [self doPerformPlainAuthentication];
}

- (void)transportDidFailToOpenConnection:(id<HJTransportForXmpp>)webSocket
                               withError:(NSError*)error
{
    self->_authStage = XMPP_PLAIN_AUTH__FAILED;
    
    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    [strongDelegate xmppClentDidFailToAuthenticate: self
                                             error: error];
}

- (void)transport:(id<HJTransportForXmpp>)webSocket
didFailToReceiveMessageWithError:(NSError*)error {
    
    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    [strongDelegate xmppClent: self
didFailToReceiveMessageWithError:error];
    
}

- (void)transportDidCloseConnection:(id<HJTransportForXmpp>)webSocket {
    
    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    [strongDelegate xmppClentDidCloseConnection: self];
}

#pragma mark - XMPPParserDelegate
- (void)xmppParser:(XMPPParser *)sender didReadRoot:(NSXMLElement *)root {
    
    NSLog(@"xmppParser:didReadRoot - %@", root);
    self->_rootNodeForParser[sender] = root;
}

- (void)xmppParserDidEnd:(XMPPParser *)sender {
    
    NSLog(@"xmppParserDidEnd");

    NSXMLElement* stanzaRoot = self->_rootNodeForParser[sender];
    NSLog(@"xmppParserDidEnd : %@", [stanzaRoot XMLString]);

    self->_rootNodeForParser.erase(sender);
    self->_parsers.erase(sender);
    
    [self processStanza: stanzaRoot];
}

- (void)xmppParser:(XMPPParser *)sender didFail:(NSError *)error {
    
    NSLog(@"xmppParser:didFail - %@", error);
    
    
    // TODO : thread safety
    self->_parsers.erase(sender);
}
- (void)xmppParserDidParseData:(XMPPParser *)sender {
    
    NSLog(@"xmppParserDidParseData:");
}

- (void)xmppParser:(id<XMPPParserProto>)sender
    didReadElement:(NSXMLElement *)element {
    
    NSLog(@"didReadElement : %@", element);
    NSXMLElement* stanzaRoot = self->_rootNodeForParser[sender];
    [stanzaRoot addChild: element];
}


- (void)processStanza:(NSXMLElement*)element {
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
        case XMPP_PLAIN_AUTH__READY_FOR_BIND_REQUEST:
        {
            [self handleBindResponse: element];
            break;
        }
        case XMPP_PLAIN_AUTH__READY_FOR_SESSION_REQUEST:
        {
            [self handleSessionResponse: element];
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

    
    // XPath is not supported by KissXML
    //
    // XPath is not supported by XMPP
    // The default (no prefix) Namespace URI for XPath queries is always '' and it cannot be redefined to 'jabber:client'
    NSXMLElement* multiMechanismsNode = [[element elementsForName: @"mechanisms"] firstObject];
    NSArray* singleMechanismNodeList = [multiMechanismsNode elementsForName: @"mechanism"];
    
    LINQCondition isPlainAuthNodePredicate = ^BOOL(NSXMLElement* singleMechanism)
    {
        NSString* nodeContent = [singleMechanism stringValue];
        BOOL result = [nodeContent isEqualToString: @"PLAIN"];
        
        return result;
    };
    NSArray* plainAuthNodes = [singleMechanismNodeList linq_where: isPlainAuthNodePredicate];
    BOOL isPlainAuthNodeExists = (0 != [plainAuthNodes count]);
    
    return isPlainAuthNodeExists;
}


#pragma mark - send request
- (void)sendAuthRequest {

    static NSString* const messageFormat =
    @"<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>%@</auth>";
    NSString* message = [NSString stringWithFormat: messageFormat, self->_accessToken];
    
    [self->_transport send: message];

}

- (void)sendBindRequest {
    
    static NSString* const bindRequest =
    @"<iq type='set' id='_bind_auth_2' xmlns='jabber:client'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'/></iq>";
    [self->_transport send: bindRequest];
}

- (void)sendSessionRequest {
    
    static NSString* const sessionRequest =
    @"<iq type='set' id='_session_auth_2' xmlns='jabber:client'><session xmlns='urn:ietf:params:xml:ns:xmpp-session'/></iq>";
    
    [self->_transport send: sessionRequest];
}


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
    else if ([[element name] isEqualToString: @"stream:features"])
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

- (void)handleBindResponse:(NSXMLElement *)element {
    
    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    //        <iq
    //            id="_bind_auth_2"
    //            type="result"
    //            xmlns="jabber:client"
    //            xmlns:stream="http://etherx.jabber.org/streams"
    //            version="1.0">
    //                <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
    //                    <jid>user+11952@xmpp-dev.healthjoy.com/21566872121436444488218507</jid>
    //                </bind>
    //        </iq>
    

    
    
    if ([HJBindResponseParser isResponseToSkip: element])
    {
        // skip unexpected stanza
        // TODO : fail or notify sentry
        return;
    }
    
    if (![HJBindResponseParser isSuccessfulBindResponse: element]) {
        
        HJXmppBindParserError* error = [HJXmppBindParserError new];
        [strongDelegate xmppClentDidFailToAuthenticate: self
                                                 error: error];
        

        [self disconnect];
        self->_authStage = XMPP_PLAIN_AUTH__FAILED;
        return;
    }
    
    self->_jidStringFromBind = [HJBindResponseParser jidFromBindResponse: element];

    // Update state
    {
        self->_authStage = XMPP_PLAIN_AUTH__READY_FOR_SESSION_REQUEST;
        [self sendSessionRequest];
    }
}

- (void)handleSessionResponse:(NSXMLElement *)element {
    
    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    //    <iq
    //        type="result"
    //        xmlns="jabber:client"
    //        id="_session_auth_2"
    //        xmlns:stream="http://etherx.jabber.org/streams"
    //        version="1.0"/>

    
    if ([HJSessionResponseParser isResponseToSkip: element]) {
        
        // skip non mathcing stanza
        // TODO : maybe notify sentry
        return;
    }
    else if ([HJSessionResponseParser isSuccessfulSessionResponse: element])
    {
        self->_authStage = XMPP_PLAIN_AUTH__COMPLETED;
        [strongDelegate xmppClentDidAuthenticate: self];
        
        
        [self doSendPresenseRequests];
    }
    else
    {
        HJXmppSessionResponseError* error = [HJXmppSessionResponseError new];

        self->_authStage = XMPP_PLAIN_AUTH__FAILED;
        [strongDelegate xmppClentDidFailToAuthenticate: self
                                                 error: error];
        
        [self disconnect];
        
        return;
    }
}

#pragma mark - Messages
- (void)handlePresenseOrMessageElement:(NSXMLElement *)element {
    
    NSLog(@"handlePresenseOrMessageElement: %@", element);
    
    BOOL isPresense = [[element name] isEqualToString: @"presence"];
    BOOL isMessage  = [[element name] isEqualToString: @"message" ];
    BOOL isHistoryResponse = [[element name] isEqualToString: @"iq"];
    
    if (isPresense)
    {
        XMPPPresence* presenseResponse = [XMPPPresence presenceFromElement: element];
        [self handlePresense: presenseResponse];
    }
    else if (isMessage)
    {
        XMPPMessage* messageResponse = [XMPPMessage messageFromElement: element];
        [self handleMessage: messageResponse];
    }
    else if (isHistoryResponse)
    {
        XMPPIQ* historyResponse = [XMPPIQ iqFromElement: element];
        [self handleHistoryResponse: historyResponse];
    }
    else
    {
        // IDLE
        // Skipping other response stanza
    }
}

- (void)handlePresense:(id<XmppPresenceProto>)element
{
    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    
    NSString* roomFromResponse = [element fromStr];
    BOOL isRoomInPendingList = [self->_pendingRooms containsObject: roomFromResponse];
    
    if (isRoomInPendingList)
    {
        [strongDelegate xmppClent: self
               didSubscribeToRoom: roomFromResponse];
        
        [self->_pendingRooms removeObject: roomFromResponse];
    }
    
    if (0 == [self->_pendingRooms count])
    {

        [strongDelegate xmppClentDidSubscribeToAllRooms: self];
    }
}

- (void)handleMessage:(id<XMPPMessageProto>)element {

    BOOL isFinMessage = NO;
    {
        NSXMLElement* castedRawMessage = (NSXMLElement*)element;
        NSArray* finElementArray = [castedRawMessage elementsForName: @"fin"];
        
        isFinMessage = (0 == [finElementArray count]);
    }
    if (isFinMessage)
    {
        [self handleFinMessage: element];
    }

    // Last message
//    <message
//        from="user+11952@xmpp-dev.healthjoy.com"
//        to="user+11952@xmpp-dev.healthjoy.com/11356033521436884287873659"
//        id="uk1yvObkAcQB"
//        xmlns="jabber:client"
//        xmlns:stream="http://etherx.jabber.org/streams"
//        version="1.0">
//            <fin
//                xmlns="urn:xmpp:mam:0"
//                queryid="878048"
//                complete="true">
//                <set xmlns="http://jabber.org/protocol/rsm">
//                    <first>1</first>
//                    <last>10</last>
//                </set>
//            </fin>
//        <no-copy xmlns="urn:xmpp:hints"/>
//    </message>

    
    // Regular message
//    <message
//        from="user+11952@xmpp-dev.healthjoy.com"
//        to="user+11952@xmpp-dev.healthjoy.com/11356033521436884287873659"
//        id="N/FSM5HBFSrG"
//        xmlns="jabber:client"
//        xmlns:stream="http://etherx.jabber.org/streams"
//        version="1.0">
//            <result
//                xmlns="urn:xmpp:mam:0"
//                id="4" queryid="878048">
//                    <forwarded xmlns="urn:xmpp:forward:0">
//                        <message
//                            xmlns="jabber:client"
//                            to="user+11952@xmpp-dev.healthjoy.com/11356033521436884287873659"
//                            from="070815_114612_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/justin.holland"
//                            type="groupchat"
//                            id="29">
//                                <body>423423</body>
//                                <x xmlns="jabber:x:event">
//                                    <composing/>
//                                </x>
//                        </message>
//                        <delay
//                            xmlns="urn:xmpp:delay"
//                            from="xmpp-dev.healthjoy.com"
//                            stamp="2015-07-08T14:17:40.817Z"/>
//                        <x
//                            xmlns="jabber:x:delay"
//                            from="xmpp-dev.healthjoy.com"
//                            stamp="20150708T14:17:40"/>
//                    </forwarded>
//            </result>
//            <no-copy xmlns="urn:xmpp:hints"/>
//    </message>

    

    // Send message request
//    <message to='070815_114612_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com' type='groupchat' xmlns='jabber:client'><body>sent message</body><html xmlns='http://jabber.org/protocol/xhtml-im'><body><p>sent message</p></body></html></message>

        // Send message response
//    <message from="070815_114612_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)" to="user+11952@xmpp-dev.healthjoy.com/11356033521436884287873659" type="groupchat" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"><body>sent message</body><html xmlns="http://jabber.org/protocol/xhtml-im"><body><p>sent message</p></body></html></message>
}

- (void)handleFinMessage:(id<XMPPMessageProto>)element
{
    
}

- (void)handleHistoryResponse:(id<XmppIqProto>)element {
    
    if ([element isErrorIQ])
    {
        [self handleHistoryFail: element];
    }
    else if ([element isResultIQ])
    {
        // IDLE
        
//        <iq from="user+11952@xmpp-dev.healthjoy.com" to="user+11952@xmpp-dev.healthjoy.com/11356033521436884287873659" type="result" id="4355073" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"/>
    }
}

- (void)handleHistoryFail:(id<XmppIqProto>)element
{
    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    NSError* error = [HJHistoryFailParser errorForFailedHistoryResponse: element];
    NSString* roomIdFromResponse = [HJHistoryFailParser roomIdForFailedHistoryResponse: element];
    
    [strongDelegate xmppClent: self
        didLoadHistoryForRoom: roomIdFromResponse
                        error: error];
    [self disconnect];
}

@end
