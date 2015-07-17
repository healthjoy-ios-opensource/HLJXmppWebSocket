//
//  HJIncomingXmppMessagesIntegrationTest.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 17/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "HJXmppClientImpl.h"
#import "HJXmppClientImpl+UnitTest.h"
#import "HJXmppClientDelegate.h"

#import "HLJWebSocketTransportForXmpp.h"
#import "HJMockSuccessAttachmentUploader.h"


static const NSTimeInterval TIMEOUT_FOR_TEST = 3000.f;

@interface HJIncomingXmppMessagesIntegrationTest : XCTestCase<HJXmppClientDelegate>
@end

@implementation HJIncomingXmppMessagesIntegrationTest
{
    HJXmppClientImpl* _sut      ;
    SRWebSocket     * _webSocket;
    HLJWebSocketTransportForXmpp* _webSocketWrapper;
    HJMockSuccessAttachmentUploader* _mockAttachments;
    NSData* _imageToSend;
    
    XCTestExpectation* _isAuthFinished;
    XCTestExpectation* _isAllPresenseResponseReceived;
    
    XCTestExpectation* _isHistoryLoaded;
    NSString* _historyRoomJid;
    NSError* _historyError;
    NSMutableArray* _historyData;
    NSMutableArray* _historyImages;
}



- (void)cleanupTestResultIvars
{
    self->_historyError = nil;
    self->_historyRoomJid = nil;
    self->_historyData = [NSMutableArray new];
    self->_historyImages = [NSMutableArray new];
}

- (void)cleanupExpectations
{
    self->_isAuthFinished = nil;
    self->_isAllPresenseResponseReceived = nil;
    self->_isHistoryLoaded = nil;
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
    static NSString* const accessToken = @"dXNlcisyODM0NkB4bXBwLmhlYWx0aGpveS5jb20AdXNlcisyODM0NgBjVEhvdDVlcTJPdkFSUlBHY3Voek12MU9ranYxMGI=";
    
    NSURL* webSocketUrl = [NSURL URLWithString: @"wss://access.gohealthinsurance.com/ws-chat/"];
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
                                                        host: @"xmpp.healthjoy.com"
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
    
    [super tearDown];
}


- (void)testHistoryWithIncomingMessagesForSingleRoom
{    
    // GIVEN
    self->_isAllPresenseResponseReceived = [self expectationWithDescription: @"All presense response received"];
    
    NSArray* rooms =
    @[
      @"070215_151803_qatest_qatest_general_question@conf.xmpp.healthjoy.com/Qatest Qatest (id 28346)"
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
    
    static NSString* const roomJid = @"070215_151803_qatest_qatest_general_question@conf.xmpp.healthjoy.com";
    self->_isHistoryLoaded = [self expectationWithDescription: @"History loaded"];
    [self->_sut loadHistoryForRoom: roomJid];
    
    
    /// THEN
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    XCTAssertNil(self->_historyError);
    XCTAssertEqual([self->_historyData count],  (NSUInteger)6);
    XCTAssertEqualObjects(self->_historyRoomJid, roomJid);
    
    id<XMPPMessageProto> message = nil;
    
    message = self->_historyData[0];
    {
        XCTAssertEqual( [message body], @"How can I help you today?");
        XCTAssertTrue( [self->_sut isMessageIncoming: message]);
    }
    
    message = self->_historyData[1];
    {
        XCTAssertEqual( [message body], @"Test tedt");
        XCTAssertFalse( [self->_sut isMessageIncoming: message]);
    }
    
    message = self->_historyData[2];
    {
        XCTAssertEqual( [message body], @"test");
        XCTAssertTrue( [self->_sut isMessageIncoming: message]);
    }
    
    message = self->_historyData[3];
    {
        XCTAssertEqual( [message body], @"1");
        XCTAssertTrue( [self->_sut isMessageIncoming: message]);
    }
    
    
    message = self->_historyData[4];
    {
        XCTAssertEqual( [message body], @"2");
        XCTAssertTrue( [self->_sut isMessageIncoming: message]);
    }
    
    message = self->_historyData[5];
    {
        XCTAssertEqual( [message body], @"3");
        XCTAssertTrue( [self->_sut isMessageIncoming: message]);
    }
}




/*
<message 
    from="user+28346@xmpp.healthjoy.com" 
    to="user+28346@xmpp.healthjoy.com/22242246181437160660980416" 
    id="3ZopsEs4QmKQ" 
    xmlns="jabber:client" 
    xmlns:stream="http://etherx.jabber.org/streams" 
    version="1.0">
 
    <result 
        xmlns="urn:xmpp:mam:0" 
        id="3" 
        queryid="5433158">
 
        <forwarded xmlns="urn:xmpp:forward:0">
            <message 
                xmlns="jabber:client" 
                to="user+28346@xmpp.healthjoy.com/22242246181437160660980416"
                from="070215_151803_qatest_qatest_general_question@conf.xmpp.healthjoy.com/elizaveta.polovaya" 
                type="groupchat" 
                id="purple7f528b6">
     
                <body>test</body>
            </message>
     
            <delay xmlns="urn:xmpp:delay" from="xmpp.healthjoy.com" stamp="2015-07-02T15:18:57.584Z"/>
            <x xmlns="jabber:x:delay" from="xmpp.healthjoy.com" stamp="20150702T15:18:57"/>
        </forwarded>
    </result>
    <no-copy xmlns="urn:xmpp:hints"/>
 </message>
*/


/*
<message from="user+28346@xmpp.healthjoy.com" to="user+28346@xmpp.healthjoy.com/22242246181437160660980416" id="RXsFfrAFs+77" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"><result xmlns="urn:xmpp:mam:0" id="2" queryid="5433158">
 
 <forwarded xmlns="urn:xmpp:forward:0"><message xmlns="jabber:client" to="user+28346@xmpp.healthjoy.com/22242246181437160660980416" from="070215_151803_qatest_qatest_general_question@conf.xmpp.healthjoy.com/Qatest Qatest (id 28346)" xml:lang="en" id="b36afeb3a92ece44" type="groupchat"><body>Test tedt</body></message><delay xmlns="urn:xmpp:delay" from="xmpp.healthjoy.com" stamp="2015-07-02T15:18:06.373Z"/><x xmlns="jabber:x:delay" from="xmpp.healthjoy.com" stamp="20150702T15:18:06"/></forwarded></result><no-copy xmlns="urn:xmpp:hints"/></message>
*/


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
}

- (void)xmppClent:(id<HJXmppClient>)sender
didSubscribeToRoom:(NSString*)roomJid
{
    NSLog(@"subscribe ok");
}

- (void)xmppClentDidSubscribeToAllRooms:(id<HJXmppClient>)sender
{
    NSLog(@"xmppClentDidSubscribeToAllRooms:");
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
    
    [self->_isAllPresenseResponseReceived fulfill];
    [self->_isAuthFinished fulfill];
}

- (void)xmppClent:(id<HJXmppClient>)sender
didFailSubscribingToRoom:(NSString*)roomJid
            error:(NSError*)error
{
    NSLog(@"subscribe fail");
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
