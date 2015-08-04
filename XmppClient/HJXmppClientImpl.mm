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
#import "HJXmppAuthResponseError.h"
#import "HJXmppSessionResponseError.h"

#import "HJBindResponseParser.h"
#import "HJSessionResponseParser.h"
#import "HJHistoryFailParser.h"
#import "HJMessageDetector.h"
#import "HJHistoryMessageParser.h"
#import "HJFinMessageParser.h"

#import "HJChatHistoryRequestProto.h"

#import "HJAttachmentUploader.h"
#import "HJXmppChatAttachment.h"
#import "HJXmppAttachmentsParser.h"


#define NSLog(...)

typedef std::set< __strong id<XMPPParserProto> > XmppParsersSet;
typedef std::map< __strong id<XMPPParserProto>, __strong NSXMLElement* > StanzaRootForParserMap;

@interface HJXmppClientImpl() <XMPPParserDelegate, HJTransportForXmppDelegate>

@property (nonatomic, readonly) NSString* jidStringFromBind;

@end


@implementation HJXmppClientImpl
{
    id<HJTransportForXmpp>   _transport             ;
    id<HJAttachmentUploader> _attachmentUpload      ;
    XmppParserBuilderBlock   _xmppParserFactory     ;
    XmppParsersSet           _parsers               ;
    StanzaRootForParserMap   _rootNodeForParser     ;
    
    NSString*                _xmppHost              ;
    NSString*                _accessToken           ;
    NSArray *                _jidStringsForRooms    ;
    
    NSMutableSet*            _pendingRooms;
    NSMutableSet*            _pendingHistoryRequests;
    NSMutableDictionary*     _queryIdForIqId        ;
    NSMutableDictionary*     _iqIdForQueryId        ;
    NSMutableDictionary*     _roomJidForQueryId     ;
    
    NSString*                _jidStringFromBind     ;

    
    
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
                attachmentsUpload:(id<HJAttachmentUploader>)attachmentUpload
                xmppParserFactory:(XmppParserBuilderBlock)xmppParserFactory
                             host:(NSString*)host
                      accessToken:(NSString*)accessToken
{
    NSParameterAssert(nil != transport);
    NSParameterAssert(nil != xmppParserFactory);
    NSParameterAssert(nil != host);
    NSParameterAssert(nil != accessToken);
    
    self = [super init];
    if (nil == self) {
        
        return nil;
    }
    
    self->_authStage = XMPP_PLAIN_AUTH__NOT_STARTED;
    
    self->_transport             = transport  ;
    [self->_transport setDelegate: self];
    
    self->_attachmentUpload = attachmentUpload;
    self->_xmppParserFactory = [xmppParserFactory copy];
    
    self->_xmppHost              = host       ;
    self->_accessToken           = accessToken;
    
    
    {
        self->_randomizerForHistoryBuilder = [HJRandomizerImpl new];
        self->_historyRequestBuilder = [[HJChatHistoryRequestBuilder alloc] initWithRandomizer: self->_randomizerForHistoryBuilder];
        
        self->_pendingHistoryRequests = [NSMutableSet new];
        self->_queryIdForIqId         = [NSMutableDictionary new];
        self->_iqIdForQueryId         = [NSMutableDictionary new];
        self->_roomJidForQueryId      = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)authenticateAsync
{
    [self->_transport open];
}

- (void)sendPresenseForRooms:(NSArray*)jidStringsForRooms {
    
    BOOL isInitialState = (XMPP_PLAIN_AUTH__NOT_STARTED == self->_authStage);
    BOOL isAuthenticatedState = (XMPP_PLAIN_AUTH__COMPLETED == self->_authStage);
    
    if (isInitialState)
    {
        self->_jidStringsForRooms = jidStringsForRooms;
        [self->_transport open];
    }
    else if (isAuthenticatedState)
    {
        self->_jidStringsForRooms = [self->_jidStringsForRooms arrayByAddingObjectsFromArray: jidStringsForRooms];
        [self doSendPresenseRequestsForRooms: jidStringsForRooms];
    }
    else
    {
        NSParameterAssert(isInitialState || isAuthenticatedState);
    }
}

- (void)doPerformPlainAuthentication {

    // the callbacks will send the presense stanza
    [self sendStreamRequest];
}

- (void)doSendPresenseRequestsForRooms:(NSArray*)jidStringsForRooms
{
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
        @"\t\t <x xmlns='http://jabber.org/protocol/muc'> \n"
        @"\t\t\t\t <history maxstanzas='0'/> \n"
        @"</x>"
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
    NSArray* presenseRequests = [jidStringsForRooms linq_select: jidToPresenseRequest];
    
    
    self->_pendingRooms = [NSMutableSet setWithArray: jidStringsForRooms];
    for (NSString* singlePresenseRequest in presenseRequests)
    {
        [self->_transport send: singlePresenseRequest];
    }
}

- (void)sendMessage:(NSString*)messageFromUser
                 to:(NSString*)roomJid
{
    NSParameterAssert(XMPP_PLAIN_AUTH__COMPLETED == self->_authStage);
    
    NSString* messageFormat =
        @"<message"
        @" to='%@'"
        @" type='groupchat'"
        @" id='%@'"
        @" xmlns='jabber:client'>"
        @"<body>%@</body>"
        @"<html xmlns='http://jabber.org/protocol/xhtml-im'>"
        @"<body>"
        @"<p>%@</p>"
        @"</body>"
        @"</html>"
        @"</message>";
    
    NSString* randomMessageId = [self->_randomizerForHistoryBuilder getRandomIdForStanza];
    
    NSXMLNode* tempNodeForEscaping = [NSXMLNode textWithStringValue: messageFromUser];
    NSString* escapedMessageFromUser = [tempNodeForEscaping XMLString];
    
    NSString* message =
        [NSString stringWithFormat: messageFormat,
            roomJid,
            randomMessageId,
            escapedMessageFromUser,
            escapedMessageFromUser];
    
    [self->_transport send: message];
}

- (void)sendAttachment:(UIImage*)attachment
                    to:(NSString*)roomJid
{
    NSParameterAssert(XMPP_PLAIN_AUTH__COMPLETED == self->_authStage);
    
    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    __weak HJXmppClientImpl* weakSelf = self;
    
    HJAttachmentUploadSuccessBlock onAttachmentUploadedBlock = ^void(id<HJXmppChatAttachment> attachment)
    {
        HJXmppClientImpl* strongSelf = weakSelf;
        [strongSelf sendAttachmentRequest: attachment
                                       to: roomJid];
    };
    
    HJAttachmentUploadErrorBlock onAttachmentUploadError = ^void(NSError* error)
    {
        HJXmppClientImpl* strongSelf = weakSelf;
        
        [strongDelegate xmppClent: strongSelf
       didFailSendingAttachmentTo: roomJid
                        withError: error];
    };
    
    [self->_attachmentUpload uploadAtachment: attachment
                          withSuccessHandler: [onAttachmentUploadedBlock copy]
                                errorHandler: [onAttachmentUploadError   copy]];
}

- (void)loadHistoryForRoom:(NSString*)roomJid
{
    BOOL isRoomOnTheList = [self isTruncatedJidOnTheRoomList: roomJid];
    if (!isRoomOnTheList)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu-zero-variadic-macro-arguments"
        NSAssert(NO, @"Attempting to request history before subscribing to the room : %@", roomJid);
#pragma clang diagnostic pop
        
        return;
    }

    id<HJChatHistoryRequestProto> request = [self->_historyRequestBuilder buildUnlimitedRequestForRoom: roomJid];
    [self addHistoryRequestToPendingList: request
                                 forRoom: roomJid];

    [self->_transport send: [request dataToSend]];
}

- (void)loadHistoryForRoom:(NSString*)roomJid
                     limit:(NSUInteger)maxMessageCount
{
    BOOL isRoomOnTheList = [self isTruncatedJidOnTheRoomList: roomJid];
    if (!isRoomOnTheList)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu-zero-variadic-macro-arguments"
        NSAssert(NO, @"Attempting to request history before subscribing to the room : %@", roomJid);
#pragma clang diagnostic pop
        
        return;
    }
    
    id<HJChatHistoryRequestProto> request = [self->_historyRequestBuilder buildRequestForRoom: roomJid
                                                                                        limit: maxMessageCount];
    [self addHistoryRequestToPendingList: request
                                 forRoom: roomJid];
    
    [self->_transport send: [request dataToSend]];
}

- (BOOL)isTruncatedJidOnTheRoomList:(NSString*)roomJid
{
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
    
    return isRoomOnTheList;
}

- (void)addHistoryRequestToPendingList:(id<HJChatHistoryRequestProto>)request
                               forRoom:(NSString*)roomJid
{
    NSString* key   = [request idForIq   ];
    NSString* value = [request idForQuery];
    
    self->_queryIdForIqId[key  ] = value;
    self->_iqIdForQueryId[value] = key  ;
    
    self->_roomJidForQueryId[value] = roomJid;
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu-zero-variadic-macro-arguments"
        NSAssert(NO, @"Unknown transport response object");
#pragma clang diagnostic pop        
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

        // TODO : extract a proper error class
        NSError* error = [HJXmppAuthResponseError new];
        
        id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
        [strongDelegate xmppClentDidFailToAuthenticate: self
                                                 error: error];
        
        [self disconnect];
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
        
        
        [self doSendPresenseRequestsForRooms: self->_jidStringsForRooms];
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

    BOOL isFinMessage     = [HJMessageDetector isFinMessage    : element];
    BOOL isHistoryMessage = [HJMessageDetector isHistoryMessage: element];
    
    if (isFinMessage)
    {
        [self handleFinMessage: element];
    }
    else if (isHistoryMessage)
    {
        [self handleMessageFromHistory: element];
    }
    else
    {
        [self handleLiveMessage: element];
    }


    
    // Regular message
    //
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
}

- (void)handleFinMessage:(id<XMPPMessageProto>)element
{
    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    
    NSString* queryId = [HJFinMessageParser queryIdFromFinMessage: element];
    NSString* iqId = self->_iqIdForQueryId[queryId];
    NSString* roomJid = self->_roomJidForQueryId[queryId];
    
    [self->_pendingHistoryRequests removeObject: iqId];
    [self->_iqIdForQueryId removeObjectForKey: queryId];
    [self->_queryIdForIqId removeObjectForKey: iqId];
    

    [strongDelegate xmppClent: self
        didLoadHistoryForRoom: roomJid
                        error: nil];
}

- (void)handleLiveMessage:(id<XMPPMessageProto>)element
{
    // "Send message" response
    //
    //
//    <message xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" from="072915_095742_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Oleksandr Dodatko" to="user+11952@xmpp-dev.healthjoy.com/14438263551438356765960568" type="groupchat" id="purple6d2e31b4" version="1.0"><archived xmlns="urn:xmpp:mam:tmp" by="072915_095742_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com" id="1438356783636318"></archived><body xmlns="jabber:client">helllll</body></message>
    
    BOOL isIncoming = [self isMessageIncoming: element];
    NSString* roomJid = [self roomForMessage: element];
    NSArray* attachments = [HJXmppAttachmentsParser parseAttachmentsOfMessage: element];

    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    [strongDelegate xmppClent: self
            didReceiveMessage: element
              withAttachments: attachments
                       atRoom: roomJid
                     incoming: isIncoming];
}

- (void)handleMessageFromHistory:(id<XMPPMessageProto>)element
{
    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    
    id<XMPPMessageProto> unwrappedMessage = [HJHistoryMessageParser unwrapHistoryMessage: element];
    BOOL isIncoming = [self isMessageIncoming: unwrappedMessage];
    NSString* roomJid = [self roomForMessage: element];
    NSArray* attachments = [HJXmppAttachmentsParser parseAttachmentsOfMessage: unwrappedMessage];
    
    [strongDelegate xmppClent: self
            didReceiveMessage: unwrappedMessage
              withAttachments: attachments
                       atRoom: roomJid
                     incoming: isIncoming];
}

- (void)handleHistoryResponse:(id<XmppIqProto>)element {
    
    if ([element isErrorIQ])
    {
        [self handleHistoryFail: element];
    }
    else if ([element isResultIQ])
    {
        NSString* historyRequestId = [element elementID];
        [self->_pendingHistoryRequests addObject: historyRequestId];
        
        /*
        <iq from="user+11952@xmpp-dev.healthjoy.com" to="user+11952@xmpp-dev.healthjoy.com/1136116387143695944183758" type="result" id="2662" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"/>
        
        <message from="user+11952@xmpp-dev.healthjoy.com" to="user+11952@xmpp-dev.healthjoy.com/1136116387143695944183758" id="2Klx2ZzfjXBK" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"><result xmlns="urn:xmpp:mam:0" id="1" queryid="6846382"><forwarded xmlns="urn:xmpp:forward:0"><message xmlns="jabber:client" to="user+11952@xmpp-dev.healthjoy.com/1136116387143695944183758" from="070815_114612_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/System Message" xml:lang="en" type="groupchat" id="eefe50c225">
        <body>How can I help you today?</body>
        </message><delay xmlns="urn:xmpp:delay" from="xmpp-dev.healthjoy.com" stamp="2015-07-08T11:46:13.145Z"/><x xmlns="jabber:x:delay" from="xmpp-dev.healthjoy.com" stamp="20150708T11:46:13"/></forwarded></result><no-copy xmlns="urn:xmpp:hints"/></message>
         */
    }
}

- (void)handleHistoryFail:(id<XmppIqProto>)element
{
    id<HJXmppClientDelegate> strongDelegate = self.listenerDelegate;
    NSError* error = [HJHistoryFailParser errorForFailedHistoryResponse: element];
    NSString* roomIdFromResponse = [HJHistoryFailParser roomIdForFailedHistoryResponse: element];
    
    NSString* keyToRemove = [element elementID];
    [self->_queryIdForIqId removeObjectForKey: keyToRemove];
    
    [strongDelegate xmppClent: self
        didLoadHistoryForRoom: roomIdFromResponse
                        error: error];
    [self disconnect];
}

#pragma mark - Attachments
- (void)sendAttachmentRequest:(id<HJXmppChatAttachment>)attachment
                           to:(NSString*)roomJid
{
    static NSString* const requestFormat =
    @"<message"
    @" to='%@'" // 071515_142949_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com
    @" type='groupchat'"
    @" id='%@'"
    @" xmlns='jabber:client'>"
    @"<body></body>"
    @"<attachment"
    @" file_name='%@'" // tmp.png
    @" size='%@'" // 120x90
    @" thumb_url='%@'" // http://cdn-dev.hjdev/objects/HNkqNvh5ca_thumb_tmp.png
    @" url='%@'/>" // http://cdn-dev.hjdev/objects/HNkqNvh5ca_tmp.png
    @"<html xmlns='http://jabber.org/protocol/xhtml-im'>"
    @"<body>"
    @"<p></p>"
    @"<a href='%@'>%@</a>" // 2x http://cdn-dev.hjdev/objects/HNkqNvh5ca_tmp.png
    @"</body>"
    @"</html>"
    @"</message>";
    
    NSString* randomMessageId = [self->_randomizerForHistoryBuilder getRandomIdForStanza];
    
    NSString* fullSizeUrl = [attachment fullSizeImageUrl];
    NSString* request =
        [NSString stringWithFormat: requestFormat,
            roomJid,
            randomMessageId,
            [attachment fileName],
            [attachment rawImageSize],
            [attachment thumbnailUrl],
            fullSizeUrl,
            fullSizeUrl, fullSizeUrl];
    
    [self->_transport send: request];
}

#pragma mark - Utils
- (BOOL)isMessageIncoming:(id<XMPPMessageProto>)element
{
    NSString* messageSender = [element fromStr];
    BOOL isSentMessage = [self->_jidStringsForRooms containsObject: messageSender];
    
    return !isSentMessage;
}

- (NSString*)roomForMessage:(id<XMPPMessageProto>)element
{
    NSString* messageSender = [element fromStr];
    NSArray* tokens = [messageSender componentsSeparatedByString: @"/"];
    
    NSString* result = [tokens firstObject];
    
    return result;
}

@end
