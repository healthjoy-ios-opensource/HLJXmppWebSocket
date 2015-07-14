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

static const NSTimeInterval TIMEOUT_FOR_TEST = 10.f;

@interface HLJWebSocketAuthIntegrationTest : XCTestCase<HJXmppClientDelegate>
@end


@implementation HLJWebSocketAuthIntegrationTest
{
    HJXmppClientImpl* _sut      ;
    SRWebSocket     * _webSocket;
    HLJWebSocketTransportForXmpp* _webSocketWrapper;
    
    
    XCTestExpectation* _isAuthFinished;
    NSError* _authError;
    
    
    XCTestExpectation* _isAllPresenseResponseReceived;
    XCTestExpectation* _isSinglePresenseResponseReceived;
    BOOL _isReceivedDidSubscribe;
    BOOL _isReceivedAllDidSubscribe;
    
    NSUInteger _didSubscribeEventsCount;
    NSUInteger _didFinishSubscribeEventsCount;
    
    XCTestExpectation* _isHistoryLoaded;
    NSError* _historyError;
    NSMutableArray* _historyData;
}

- (void)cleanupTestResultIvars
{
    self->_authError = nil;
    self->_isReceivedDidSubscribe    = NO;
    self->_isReceivedAllDidSubscribe = NO;
    self->_didSubscribeEventsCount   = 0;
    self->_didFinishSubscribeEventsCount = 0;
    
    self->_historyError = nil;
    self->_historyData = [NSMutableArray new];
}

- (void)cleanupExpectations
{
    self->_isAuthFinished = nil;
    self->_isSinglePresenseResponseReceived = nil;
    self->_isAllPresenseResponseReceived = nil;
    self->_isHistoryLoaded = nil;
}

- (void)setUp
{
    [super setUp];
    [self cleanupExpectations];

    [self cleanupTestResultIvars];
    
    static NSString* const jid = @"070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)";

    
    // !!! A token needs manual updating
    static NSString* const accessToken = @"dXNlcisxMTk1MkB4bXBwLWRldi5oZWFsdGhqb3kuY29tAHVzZXIrMTE5NTIAN3FKWjJIOFQ5V0FtWTNCU2M1Qkk3WVBOVXk3RG5E";
    
    NSURL* webSocketUrl = [NSURL URLWithString: @"wss://gohealth-dev.hjdev/ws-chat/"];
    self->_webSocket = [[SRWebSocket alloc] initWithURL: webSocketUrl];
    
    self->_webSocketWrapper = [[HLJWebSocketTransportForXmpp alloc] initWithWebSocket: self->_webSocket];
    
    
    
    
    XmppParserBuilderBlock parserFactory = ^id<XMPPParserProto>()
    {
        XMPPParser* parser = [[XMPPParser alloc] initWithDelegate: nil
                                                    delegateQueue: NULL];
        return parser;
    };
    self->_sut = [[HJXmppClientImpl alloc] initWithTransport: self->_webSocketWrapper
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
    
    //// WHEN
    self->_isReceivedDidSubscribe    = nil;
    self->_isReceivedAllDidSubscribe = nil;
    
    
    self->_isHistoryLoaded = [self expectationWithDescription: @"History loaded"];
    [self->_sut loadHistoryForRoom: @"070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com"];
    
    
    /// THEN
    [self waitForExpectationsWithTimeout: TIMEOUT_FOR_TEST
                                 handler: handlerOrNil];
    
    XCTAssertNil(self->_historyError);
    XCTAssertTrue([self->_historyData count] > 0);
}

#pragma mark - HJXmppClientDelegate
- (void)xmppClent:(id<HJXmppClient>)sender
didReceiveMessage:(id<XMPPMessageProto>)message
{
    NSLog(@"message");
    [self->_historyData addObject: message];
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
    self->_historyError = maybeError;
}

@end
