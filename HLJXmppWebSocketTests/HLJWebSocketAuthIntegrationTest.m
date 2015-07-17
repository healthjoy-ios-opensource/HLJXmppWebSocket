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

#import "HJXmppChatAttachment.h"
#import "HJMockSuccessAttachmentUploader.h"


static const NSTimeInterval TIMEOUT_FOR_TEST = 10.f;

@interface HLJWebSocketAuthIntegrationTest : XCTestCase<HJXmppClientDelegate>
@end


@implementation HLJWebSocketAuthIntegrationTest
{
    HJXmppClientImpl* _sut      ;
    SRWebSocket     * _webSocket;
    HLJWebSocketTransportForXmpp* _webSocketWrapper;
    HJMockSuccessAttachmentUploader* _mockAttachments;
    
    
    XCTestExpectation* _isAuthFinished;
    NSError* _authError;
    NSData* _imageToSend;
    
    
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
    NSMutableArray* _historyImages;
    
    XCTestExpectation* _isSendMessageEchoReceived;
    id<XMPPMessageProto> _sentMessageEcho;
    NSString* _roomOfMessageEcho;
    NSArray* _attachmentsFromMessageEcho;
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
    self->_historyImages = [NSMutableArray new];
    
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
    self->_attachmentsFromMessageEcho = nil;
}

- (void)setUp
{
    [super setUp];
    [self cleanupExpectations];

    [self cleanupTestResultIvars];
    
    NSBundle* mainBundle = [NSBundle bundleForClass: [self class]];
    NSString* filePath = [mainBundle pathForResource: @"monkey-selfie"
                                              ofType: @"jpg"];
    self->_imageToSend = [NSData dataWithContentsOfFile: filePath];
    
    
    // !!! A token needs manual updating
    static NSString* const accessToken = @"dXNlcisxMTk1MkB4bXBwLWRldi5oZWFsdGhqb3kuY29tAHVzZXIrMTE5NTIAZHVseGdybExwS3hicXNFcXdYSGVtZEJmOUF0MDFo";
    
    NSURL* webSocketUrl = [NSURL URLWithString: @"wss://gohealth-dev.hjdev/ws-chat/"];
    self->_webSocket = [[SRWebSocket alloc] initWithURL: webSocketUrl];
    
    self->_webSocketWrapper = [[HLJWebSocketTransportForXmpp alloc] initWithWebSocket: self->_webSocket];
    
    
    
    self->_mockAttachments = [HJMockSuccessAttachmentUploader new];
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
                                                 accessToken: accessToken];
    self->_sut.listenerDelegate = self;
}

- (void)tearDown
{
    [self cleanupTestResultIvars];
    [self cleanupExpectations];
    
    [self->_sut disconnect];
    [self->_webSocket close];
    
    self->_imageToSend = nil;
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

- (void)testSingleAttachmentFromHistory
{
    // GIVEN
    self->_isAllPresenseResponseReceived = [self expectationWithDescription: @"All presense response received"];
    
    NSArray* rooms =
    @[
      @"071715_112152_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)"
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
    
    static NSString* const roomJid = @"071715_112152_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com";
    self->_isHistoryLoaded = [self expectationWithDescription: @"History loaded"];
    [self->_sut loadHistoryForRoom: roomJid];
    
    
    /// THEN
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    XCTAssertNil(self->_historyError);
    XCTAssertEqual([self->_historyData count],  (NSUInteger)3);
    XCTAssertEqualObjects(self->_historyRoomJid, roomJid);
    
    XCTAssertEqual([self->_historyImages count], (NSUInteger)1);
    
    id<HJXmppChatAttachment> attachment = self->_historyImages[0];
    {
        XCTAssertEqualObjects([attachment fileName], @"IMG_0080.PNG");
        XCTAssertEqualObjects([attachment rawImageSize], @"80x120");
        XCTAssertEqualObjects([attachment fullSizeImageUrl], @"http://cdn-dev.hjdev/objects/9iJzPaQl2M_IMG_0080.PNG");
        XCTAssertEqualObjects([attachment thumbnailUrl], @"http://cdn-dev.hjdev/objects/9iJzPaQl2M_thumb_IMG_0080.PNG");
        
        XCTAssertThrows([attachment imageSize]);
    }
    
    /*
    <message from="user+11952@xmpp-dev.healthjoy.com" to="user+11952@xmpp-dev.healthjoy.com/19864967261437132266909917" id="ReNcM3JfCV3a" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"><result xmlns="urn:xmpp:mam:0" id="2" queryid="6026788"><forwarded xmlns="urn:xmpp:forward:0"><message xmlns="jabber:client" to="user+11952@xmpp-dev.healthjoy.com/19864967261437132266909917" from="071715_112152_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)" type="groupchat"><body/><attachment file_name="IMG_0080.PNG" size="80x120" thumb_url="http://cdn-dev.hjdev/objects/9iJzPaQl2M_thumb_IMG_0080.PNG" url="http://cdn-dev.hjdev/objects/9iJzPaQl2M_IMG_0080.PNG"/><html xmlns="http://jabber.org/protocol/xhtml-im"><body><p/><a href="http://cdn-dev.hjdev/objects/9iJzPaQl2M_IMG_0080.PNG">http://cdn-dev.hjdev/objects/9iJzPaQl2M_IMG_0080.PNG</a></body></html></message><delay xmlns="urn:xmpp:delay" from="xmpp-dev.healthjoy.com" stamp="2015-07-17T11:24:17.834Z"/><x xmlns="jabber:x:delay" from="xmpp-dev.healthjoy.com" stamp="20150717T11:24:17"/></forwarded></result><no-copy xmlns="urn:xmpp:hints"/></message>
   */
}

- (void)testSingleAttachmentWithTextFromHistory
{
    /*
    <message from="user+11952@xmpp-dev.healthjoy.com" to="user+11952@xmpp-dev.healthjoy.com/29685965691437133878966496" id="lsXKwxFym3rv" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"><result xmlns="urn:xmpp:mam:0" id="2" queryid="9010833"><forwarded xmlns="urn:xmpp:forward:0"><message xmlns="jabber:client" to="user+11952@xmpp-dev.healthjoy.com/29685965691437133878966496" from="071715_115021_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)" type="groupchat"><body>Attachment and text in one message</body><attachment file_name="IMG_0080.PNG" size="80x120" thumb_url="http://cdn-dev.hjdev/objects/T386GAul98_thumb_IMG_0080.PNG" url="http://cdn-dev.hjdev/objects/T386GAul98_IMG_0080.PNG"/><html xmlns="http://jabber.org/protocol/xhtml-im"><body><p>Attachment and text in one message</p><a href="http://cdn-dev.hjdev/objects/T386GAul98_IMG_0080.PNG">http://cdn-dev.hjdev/objects/T386GAul98_IMG_0080.PNG</a></body></html></message><delay xmlns="urn:xmpp:delay" from="xmpp-dev.healthjoy.com" stamp="2015-07-17T11:51:00.049Z"/><x xmlns="jabber:x:delay" from="xmpp-dev.healthjoy.com" stamp="20150717T11:51:00"/></forwarded></result><no-copy xmlns="urn:xmpp:hints"/></message>
     */
    
    
    // GIVEN
    self->_isAllPresenseResponseReceived = [self expectationWithDescription: @"All presense response received"];
    
    NSArray* rooms =
    @[
      @"071715_115021_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)"
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
    
    static NSString* const roomJid = @"071715_115021_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com";
    self->_isHistoryLoaded = [self expectationWithDescription: @"History loaded"];
    [self->_sut loadHistoryForRoom: roomJid];
    
    
    /// THEN
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    XCTAssertNil(self->_historyError);
    XCTAssertEqualObjects(self->_historyRoomJid, roomJid);
    
    
    XCTAssertEqual([self->_historyData count],  (NSUInteger)2);
    id<XMPPMessageProto> messageWithAttachment = self->_historyData[1];
    {
        XCTAssertEqualObjects([messageWithAttachment body], @"Attachment and text in one message");
    }
    
    XCTAssertEqual([self->_historyImages count], (NSUInteger)1);
    id<HJXmppChatAttachment> attachment = self->_historyImages[0];
    {
        XCTAssertEqualObjects([attachment fileName], @"IMG_0080.PNG");
        XCTAssertEqualObjects([attachment rawImageSize], @"80x120");
        XCTAssertEqualObjects([attachment fullSizeImageUrl], @"http://cdn-dev.hjdev/objects/T386GAul98_IMG_0080.PNG");
        XCTAssertEqualObjects([attachment thumbnailUrl], @"http://cdn-dev.hjdev/objects/T386GAul98_thumb_IMG_0080.PNG");
        
        XCTAssertThrows([attachment imageSize]);
    }
}

- (void)testMultipleAttachmentsInOneMessageWithTextFromHistory
{
    /*
<message from="user+11952@xmpp-dev.healthjoy.com" to="user+11952@xmpp-dev.healthjoy.com/5821303091437135703858160" id="+aO0Oh7Zzr15" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"><result xmlns="urn:xmpp:mam:0" id="2" queryid="7453827"><forwarded xmlns="urn:xmpp:forward:0"><message xmlns="jabber:client" to="user+11952@xmpp-dev.healthjoy.com/5821303091437135703858160" from="071715_121652_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)" type="groupchat"><body>Message With three images</body><attachment file_name="IMG_0050.PNG" size="67x120" thumb_url="http://cdn-dev.hjdev/objects/krXhb9qHay_thumb_IMG_0050.PNG" url="http://cdn-dev.hjdev/objects/krXhb9qHay_IMG_0050.PNG"/><attachment file_name="IMG_0080.PNG" size="80x120" thumb_url="http://cdn-dev.hjdev/objects/Bp1gIVBhES_thumb_IMG_0080.PNG" url="http://cdn-dev.hjdev/objects/Bp1gIVBhES_IMG_0080.PNG"/><attachment file_name="IMG_0084.PNG" size="80x120" thumb_url="http://cdn-dev.hjdev/objects/IMpRM0dalB_thumb_IMG_0084.PNG" url="http://cdn-dev.hjdev/objects/IMpRM0dalB_IMG_0084.PNG"/><html xmlns="http://jabber.org/protocol/xhtml-im"><body><p>Message With three images</p><a href="http://cdn-dev.hjdev/objects/krXhb9qHay_IMG_0050.PNG">http://cdn-dev.hjdev/objects/krXhb9qHay_IMG_0050.PNG</a><a href="http://cdn-dev.hjdev/objects/Bp1gIVBhES_IMG_0080.PNG">http://cdn-dev.hjdev/objects/Bp1gIVBhES_IMG_0080.PNG</a><a href="http://cdn-dev.hjdev/objects/IMpRM0dalB_IMG_0084.PNG">http://cdn-dev.hjdev/objects/IMpRM0dalB_IMG_0084.PNG</a></body></html></message><delay xmlns="urn:xmpp:delay" from="xmpp-dev.healthjoy.com" stamp="2015-07-17T12:17:44.689Z"/><x xmlns="jabber:x:delay" from="xmpp-dev.healthjoy.com" stamp="20150717T12:17:44"/></forwarded></result><no-copy xmlns="urn:xmpp:hints"/></message>
     */
    
    
    // GIVEN
    self->_isAllPresenseResponseReceived = [self expectationWithDescription: @"All presense response received"];
    
    NSArray* rooms =
    @[
      @"071715_121652_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)"
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
    
    static NSString* const roomJid = @"071715_121652_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com";
    self->_isHistoryLoaded = [self expectationWithDescription: @"History loaded"];
    [self->_sut loadHistoryForRoom: roomJid];
    
    
    /// THEN
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    XCTAssertNil(self->_historyError);
    XCTAssertEqualObjects(self->_historyRoomJid, roomJid);
    
    XCTAssertEqual([self->_historyData count],  (NSUInteger)2);
    id<XMPPMessageProto> messageWithAttachment = self->_historyData[1];
    {
        XCTAssertEqualObjects([messageWithAttachment body], @"Message With three images");
    }
    
    
    XCTAssertEqual([self->_historyImages count], (NSUInteger)3);
    id<HJXmppChatAttachment> attachment = nil;
    attachment = self->_historyImages[0];
    {
        XCTAssertEqualObjects([attachment fileName], @"IMG_0050.PNG");
        XCTAssertEqualObjects([attachment rawImageSize], @"67x120");
        XCTAssertEqualObjects([attachment fullSizeImageUrl], @"http://cdn-dev.hjdev/objects/krXhb9qHay_IMG_0050.PNG");
        XCTAssertEqualObjects([attachment thumbnailUrl], @"http://cdn-dev.hjdev/objects/krXhb9qHay_thumb_IMG_0050.PNG");
        
        XCTAssertThrows([attachment imageSize]);
    }
    
    attachment = self->_historyImages[1];
    {
        XCTAssertEqualObjects([attachment fileName], @"IMG_0080.PNG");
        XCTAssertEqualObjects([attachment rawImageSize], @"80x120");
        XCTAssertEqualObjects([attachment fullSizeImageUrl], @"http://cdn-dev.hjdev/objects/Bp1gIVBhES_IMG_0080.PNG");
        XCTAssertEqualObjects([attachment thumbnailUrl], @"http://cdn-dev.hjdev/objects/Bp1gIVBhES_thumb_IMG_0080.PNG");
        
        XCTAssertThrows([attachment imageSize]);
    }
    
    attachment = self->_historyImages[2];
    {
        XCTAssertEqualObjects([attachment fileName], @"IMG_0084.PNG");
        XCTAssertEqualObjects([attachment rawImageSize], @"80x120");
        XCTAssertEqualObjects([attachment fullSizeImageUrl], @"http://cdn-dev.hjdev/objects/IMpRM0dalB_IMG_0084.PNG");
        XCTAssertEqualObjects([attachment thumbnailUrl], @"http://cdn-dev.hjdev/objects/IMpRM0dalB_thumb_IMG_0084.PNG");
        
        XCTAssertThrows([attachment imageSize]);
    }
}

- (void)testAttachmentSending
{
    // GIVEN
    self->_isAllPresenseResponseReceived = [self expectationWithDescription: @"All presense response received"];
    
    NSArray* rooms =
    @[
      @"071715_130351_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)"
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
    
    static NSString* const roomJid = @"071715_130351_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com";
    self->_isHistoryLoaded = [self expectationWithDescription: @"History loaded"];
    [self->_sut loadHistoryForRoom: roomJid];
    
    
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    self->_isHistoryLoaded = nil;
    
    /// THEN
    self->_isSendMessageEchoReceived = [self expectationWithDescription: @"Outcoming message echo received"];
    
    [self->_sut sendAttachment: self->_imageToSend
                            to: roomJid];
    
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    XCTAssertNotNil(self->_sentMessageEcho);
    XCTAssertEqualObjects([self->_sentMessageEcho fromStr], @"071715_130351_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)");
    XCTAssertEqualObjects(self->_roomOfMessageEcho, roomJid);
    
    
    NSString* expectedToStr = [self->_sut jidStringFromBind];
    XCTAssertEqualObjects([self->_sentMessageEcho toStr], expectedToStr);
    
    NSString* trimmedBody = [[self->_sentMessageEcho body] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    XCTAssertEqual([trimmedBody length], (NSUInteger)0 );
    
    
    XCTAssertNotNil(self->_attachmentsFromMessageEcho);
    XCTAssertEqual([self->_attachmentsFromMessageEcho count], (NSUInteger)1);
}


#pragma mark - HJXmppClientDelegate
- (void)xmppClent:(id<HJXmppClient>)sender
didReceiveMessage:(id<XMPPMessageProto>)message
  withAttachments:(NSArray*)attachments
           atRoom:(NSString*)roomJid
         incoming:(BOOL)isMessageIncoming
{
    NSLog(@"message");
    [self->_historyData addObject: message];
    [self->_historyImages addObjectsFromArray: attachments];
    
    if (!isMessageIncoming)
    {
        self->_roomOfMessageEcho = roomJid;
        self->_sentMessageEcho = message;
        self->_attachmentsFromMessageEcho = attachments;
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
didFailSendingAttachmentTo:(NSString*)roomJid
        withError:(NSError*)error
{
    
}

@end
