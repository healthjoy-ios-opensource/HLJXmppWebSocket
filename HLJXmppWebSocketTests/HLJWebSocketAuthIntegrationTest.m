//
//  HLJWebSocketAuthIntegrationTest.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/10/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import <SocketRocket/SRWebSocket.h>
#import <XmppFrameworkParsers/XmppFrameworkParsers.h>
#import <HLJXmppWebSocket/HLJXmppWebSocket.h>

#import "HJXmppClientImpl.h"
#import "HLJWebSocketTransportForXmpp.h"
#import "HJXmppClientImpl+UnitTest.h"
#import "HJMockAttachmentUploader.h"


static const NSTimeInterval TIMEOUT_FOR_TEST = 10.f;

@interface HLJWebSocketAuthIntegrationTest : XCTestCase<HJXmppClientDelegate>
@end


@implementation HLJWebSocketAuthIntegrationTest
{
    HJXmppClientImpl* _sut      ;
    SRWebSocket     * _webSocket;
    HLJWebSocketTransportForXmpp* _webSocketWrapper;
    HJMockAttachmentUploader* _mockAttachments;
    
    
    XCTestExpectation* _isAuthFinished;
    NSError* _authError;
    
    
    XCTestExpectation* _isAllPresenseResponseReceived;
    XCTestExpectation* _isSinglePresenseResponseReceived;
    BOOL _isReceivedDidSubscribe;
    BOOL _isReceivedAllDidSubscribe;
    
    NSUInteger _didSubscribeEventsCount;
    NSUInteger _didFinishSubscribeEventsCount;
    
    XCTestExpectation* _isHistoryLoaded;
    NSString* _historyRoomJid;
    NSError* _historyError;
    NSMutableArray* _historyData;
    
    XCTestExpectation* _isSendMessageEchoReceived;
    id<XMPPMessageProto> _sentMessageEcho;
    NSString* _roomOfMessageEcho;
}

- (void)cleanupTestResultIvars
{
    self->_authError = nil;
    self->_isReceivedDidSubscribe    = NO;
    self->_isReceivedAllDidSubscribe = NO;
    self->_didSubscribeEventsCount   = 0;
    self->_didFinishSubscribeEventsCount = 0;
    
    self->_historyError = nil;
    self->_historyRoomJid = nil;
    self->_historyData = [NSMutableArray new];
    
    self->_sentMessageEcho = nil;
    self->_roomOfMessageEcho = nil;
}

- (void)cleanupExpectations
{
    self->_isAuthFinished = nil;
    self->_isSinglePresenseResponseReceived = nil;
    self->_isAllPresenseResponseReceived = nil;
    self->_isHistoryLoaded = nil;
    self->_isSendMessageEchoReceived = nil;
}

- (void)setUp
{
    [super setUp];
    [self cleanupExpectations];

    [self cleanupTestResultIvars];
    
    static NSString* const jid = @"070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)";

    
    // !!! A token needs manual updating
    static NSString* const accessToken = @"dXNlcisxMTk1MkB4bXBwLWRldi5oZWFsdGhqb3kuY29tAHVzZXIrMTE5NTIAZHVseGdybExwS3hicXNFcXdYSGVtZEJmOUF0MDFo";
    
    NSURL* webSocketUrl = [NSURL URLWithString: @"wss://gohealth-dev.hjdev/ws-chat/"];
    self->_webSocket = [[SRWebSocket alloc] initWithURL: webSocketUrl];
    
    self->_webSocketWrapper = [[HLJWebSocketTransportForXmpp alloc] initWithWebSocket: self->_webSocket];
    
    
    
    self->_mockAttachments = [HJMockAttachmentUploader new];
    XmppParserBuilderBlock parserFactory = ^id<XMPPParserProto>()
    {
        XMPPParser* parser = [[XMPPParser alloc] initWithDelegate: nil
                                                    delegateQueue: NULL];
        return parser;
    };
    self->_sut = [[HJXmppClientImpl alloc] initWithTransport: self->_webSocketWrapper
                                           attachmentsUpload: self->_mockAttachments
                                           xmppParserFactory: parserFactory
                                                        host: @"xmpp-dev.healthjoy.com"
                                                 accessToken: accessToken
                                               userJidString: jid];
    self->_sut.listenerDelegate = self;
}

- (void)tearDown
{
    [self cleanupTestResultIvars];
    [self cleanupExpectations];
    
    [self->_sut disconnect];
    [self->_webSocket close];
    
    self->_sut = nil;
    self->_webSocket = nil;
    
    self->_authError = nil;
    
    [super tearDown];
}

- (void)testSuccessfulConnection
{
    self->_isAuthFinished = [self expectationWithDescription: @"XMPP auth passed"];
    
    NSArray* rooms =
    @[
      @"070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)",
      
      @"070815_114612_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)"
    ];
    
    XCWaitCompletionHandler handlerOrNil = ^void(NSError *error)
    {
        // TODO : add asserts
        NSLog(@"done");
    };
    
    [self->_sut sendPresenseForRooms: rooms];
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    
    
    XCTAssertNil(self->_authError);
}

- (void)testDidSubscribeEventsFiresForSingleRoom
{
    self->_isSinglePresenseResponseReceived = [self expectationWithDescription: @"Single presence response received"];
    self->_isAllPresenseResponseReceived    = [self expectationWithDescription: @"All presense response received"   ];
    
    NSArray* rooms =
    @[
      @"070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)"
    ];
    
    XCWaitCompletionHandler handlerOrNil = ^void(NSError *error)
    {
        // TODO : add asserts
        NSLog(@"done");
    };
    
    [self->_sut sendPresenseForRooms: rooms];
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    XCTAssertTrue(self->_isReceivedDidSubscribe);
    XCTAssertTrue(self->_isReceivedAllDidSubscribe);
    XCTAssertEqual(self->_didSubscribeEventsCount, (NSUInteger)1);
    XCTAssertEqual(self->_didFinishSubscribeEventsCount, (NSUInteger)1);
}

- (void)testDidSubscribeEventsFiresForEachRooms
{
    self->_isAllPresenseResponseReceived = [self expectationWithDescription: @"All presense response received"   ];
    
    NSArray* rooms =
    @[
      @"070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)",
      @"070815_114612_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)"
    ];
    
    XCWaitCompletionHandler handlerOrNil = ^void(NSError *error)
    {
        // TODO : add asserts
        NSLog(@"done");
    };
    
    [self->_sut sendPresenseForRooms: rooms];
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    XCTAssertTrue(self->_isReceivedDidSubscribe);
    XCTAssertTrue(self->_isReceivedAllDidSubscribe);
    XCTAssertEqual(self->_didSubscribeEventsCount, (NSUInteger)2);
    XCTAssertEqual(self->_didFinishSubscribeEventsCount, (NSUInteger)1);
}


- (void)testSuccessfulHistoryFetchForSingleRoom
{
    // GIVEN
    self->_isAllPresenseResponseReceived = [self expectationWithDescription: @"All presense response received"];
    
    NSArray* rooms =
    @[
      @"071515_135928_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)"
      ];
    
    XCWaitCompletionHandler handlerOrNil = ^void(NSError *error)
    {
        // TODO : add asserts
        NSLog(@"done");
    };
    
    [self->_sut sendPresenseForRooms: rooms];
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];

    
    //// WHEN
    self->_isReceivedDidSubscribe    = nil;
    self->_isReceivedAllDidSubscribe = nil;
    
    static NSString* const roomJid = @"071515_135928_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com";
    self->_isHistoryLoaded = [self expectationWithDescription: @"History loaded"];
    [self->_sut loadHistoryForRoom: roomJid];
    
    
    /// THEN
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    XCTAssertNil(self->_historyError);
    XCTAssertEqual([self->_historyData count],  (NSUInteger)1);
    XCTAssertEqualObjects(self->_historyRoomJid, roomJid);
}

- (void)testMessageSending
{
    /*
    <presence from='user+11952@xmpp-dev.healthjoy.com/24536774811436968628882896' to='071515_142949_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)' xmlns='jabber:client'><x xmlns='http://jabber.org/protocol/muc'/></presence>
    
    <iq type='set' id='7344163'><query xmlns='urn:xmpp:mam:0' queryid='5999853'><x xmlns='jabber:x:data'><field var='FORM_TYPE'><value>urn:xmpp:mam:0</value></field><field var='with'><value>071515_142949_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com</value></field><field var='start'><value>1970-01-01T00:00:00Z</value></field></x><set xmlns='http://jabber.org/protocol/rsm'><max>1000</max></set></query></iq>
    
    <message to='071515_142949_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com' type='groupchat' xmlns='jabber:client'><body>test send message (manual)</body><html xmlns='http://jabber.org/protocol/xhtml-im'><body><p>test send message (manual)</p></body></html></message>
     
     
     <message from="071515_142949_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)" to="user+11952@xmpp-dev.healthjoy.com/24536774811436968628882896" type="groupchat" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"><body>test send message (manual)</body><html xmlns="http://jabber.org/protocol/xhtml-im"><body><p>test send message (manual)</p></body></html></message>
    */

    
    
    // GIVEN
    self->_isAllPresenseResponseReceived = [self expectationWithDescription: @"All presense response received"];
    
    NSArray* rooms =
    @[
      @"071515_142949_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)"
      ];
    
    XCWaitCompletionHandler handlerOrNil = ^void(NSError *error)
    {
        // TODO : add asserts
        NSLog(@"done");
    };
    
    [self->_sut sendPresenseForRooms: rooms];
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    //// WHEN
    self->_isReceivedDidSubscribe    = nil;
    self->_isReceivedAllDidSubscribe = nil;
    
    static NSString* const roomJid = @"071515_142949_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com";
    self->_isHistoryLoaded = [self expectationWithDescription: @"History loaded"];
    [self->_sut loadHistoryForRoom: roomJid];
    
    
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    self->_isHistoryLoaded = nil;
    
    /// THEN
    self->_isSendMessageEchoReceived = [self expectationWithDescription: @"Outcoming message echo received"];
    
    NSDate* nowDate = [NSDate date];
    NSString* outgoingMessage = [NSString stringWithFormat: @"test send message + %@", nowDate];
    [self->_sut sendMessage: outgoingMessage
                         to: roomJid];
    
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    XCTAssertNotNil(self->_sentMessageEcho);
    XCTAssertEqualObjects([self->_sentMessageEcho fromStr], @"071515_142949_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)");
    XCTAssertEqualObjects(self->_roomOfMessageEcho, roomJid);
    

    NSString* expectedToStr = [self->_sut jidStringFromBind];
    XCTAssertEqualObjects([self->_sentMessageEcho toStr], expectedToStr);
    XCTAssertEqualObjects([self->_sentMessageEcho body], outgoingMessage);
}

- (void)testAttachmentSending
{
    XCTFail(@"TODO : Write a test");
    
    // Request
    //
    /*
    <message
        to='071515_142949_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com' 
        type='groupchat' 
        xmlns='jabber:client'>
            <body>
            </body>
     
            <attachment 
                 file_name='tmp.png' 
                 size='120x90' 
                 thumb_url='http://cdn-dev.hjdev/objects/HNkqNvh5ca_thumb_tmp.png' 
                 url='http://cdn-dev.hjdev/objects/HNkqNvh5ca_tmp.png'/>
             
            <html xmlns='http://jabber.org/protocol/xhtml-im'>
                <body>
                    <p></p>
                    <a href='http://cdn-dev.hjdev/objects/HNkqNvh5ca_tmp.png'>http://cdn-dev.hjdev/objects/HNkqNvh5ca_tmp.png</a>
                </body>
            </html>
     </message>
    */
    
    
    
    // Response
    //
    /*
    <message 
         from="071515_142949_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)" 
         to="user+11952@xmpp-dev.healthjoy.com/24536774811436968628882896" 
         type="groupchat" 
         xmlns="jabber:client" 
         xmlns:stream="http://etherx.jabber.org/streams" 
         version="1.0">
             <body/>
      
             <attachment 
                  file_name="tmp.png" 
                  size="120x90" thumb_url="http://cdn-dev.hjdev/objects/HNkqNvh5ca_thumb_tmp.png" url="http://cdn-dev.hjdev/objects/HNkqNvh5ca_tmp.png"/><html xmlns="http://jabber.org/protocol/xhtml-im"><body><p/><a href="http://cdn-dev.hjdev/objects/HNkqNvh5ca_tmp.png">http://cdn-dev.hjdev/objects/HNkqNvh5ca_tmp.png</a></body></html></message>
    */
}

#pragma mark - HJXmppClientDelegate
- (void)xmppClent:(id<HJXmppClient>)sender
didReceiveMessage:(id<XMPPMessageProto>)message
           atRoom:(NSString*)roomJid
         incoming:(BOOL)isMessageIncoming
{
    NSLog(@"message");
    [self->_historyData addObject: message];
    
    if (!isMessageIncoming)
    {
        self->_roomOfMessageEcho = roomJid;
        self->_sentMessageEcho = message;
        [self->_isSendMessageEchoReceived fulfill];
    }
}

- (void)xmppClent:(id<HJXmppClient>)sender
didSubscribeToRoom:(NSString*)roomJid
{
    NSLog(@"subscribe ok");

    ++self->_didSubscribeEventsCount;
    self->_isReceivedDidSubscribe = YES;
    [self->_isSinglePresenseResponseReceived fulfill];
}

- (void)xmppClentDidSubscribeToAllRooms:(id<HJXmppClient>)sender
{
    NSLog(@"xmppClentDidSubscribeToAllRooms:");
    
    ++self->_didFinishSubscribeEventsCount;
    self->_isReceivedAllDidSubscribe = YES;
    [self->_isAllPresenseResponseReceived fulfill];
}


- (void)xmppClentDidAuthenticate:(id<HJXmppClient>)sender
{
    NSLog(@"auth ok");
    [self->_isAuthFinished fulfill];
}

- (void)xmppClentDidFailToAuthenticate:(id<HJXmppClient>)sender
                                 error:(NSError*)error
{
    NSLog(@"auth fail");
    self->_authError = error;
    
    [self->_isAllPresenseResponseReceived fulfill];
    [self->_isSinglePresenseResponseReceived fulfill];
    [self->_isAuthFinished fulfill];
}

- (void)xmppClent:(id<HJXmppClient>)sender
didFailSubscribingToRoom:(NSString*)roomJid
            error:(NSError*)error
{
    NSLog(@"subscribe fail");
    [self->_isSinglePresenseResponseReceived fulfill];
    [self->_isAllPresenseResponseReceived fulfill];
}

- (void)xmppClent:(id<HJXmppClient>)sender
didFailToReceiveMessageWithError:(NSError*)error {
    
    NSLog(@"message fail");
}

- (void)xmppClentDidCloseConnection:(id<HJXmppClient>)sender {
    
    NSLog(@"close");
}

- (void)xmppClent:(id<HJXmppClient>)sender
didLoadHistoryForRoom:(NSString*)roomJid
            error:(NSError*)maybeError
{
    self->_historyRoomJid = roomJid;
    self->_historyError = maybeError;
    [self->_isHistoryLoaded fulfill];
}

- (void)xmppClent:(id<HJXmppClient>)sender
didSendAttachmentTo:(NSString*)roomJid
{
    
}

- (void)xmppClent:(id<HJXmppClient>)sender
didFailSendingAttachmentTo:(NSString*)roomJid
        withError:(NSError*)error
{
    
}

@end
