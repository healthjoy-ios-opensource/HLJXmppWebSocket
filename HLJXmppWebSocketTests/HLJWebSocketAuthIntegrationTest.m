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

@interface HLJWebSocketAuthIntegrationTest : XCTestCase<HJXmppClientDelegate>
@end


@implementation HLJWebSocketAuthIntegrationTest
{
    HJXmppClientImpl* _sut      ;
    SRWebSocket     * _webSocket;
    HLJWebSocketTransportForXmpp* _webSocketWrapper;
    
    
    XCTestExpectation* _isAuthFinished;
    
    NSError* _authError;
}


- (void)setUp {
    [super setUp];

    static NSString* const jid = @"070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)";

    
    // !!! needs manual updating
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
    
    
    self->_authError = nil;
}

- (void)tearDown {
    
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
    [self waitForExpectationsWithTimeout: 3000.f
                                 handler: handlerOrNil];
    
    
    
    XCTAssertNil(self->_authError);
}


#pragma mark - HJXmppClientDelegate
- (void)xmppClent:(id<HJXmppClient>)sender
didReceiveMessage:(id<XMPPMessageProto>)message
{
    NSLog(@"message");
}

- (void)xmppClent:(id<HJXmppClient>)sender
didSubscribeToRoom:(NSString*)roomJid
{
    NSLog(@"subscribe ok");
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
    [self->_isAuthFinished fulfill];
}

- (void)xmppClent:(id<HJXmppClient>)sender
didFailSubscribingToRoom:(NSString*)roomJid
            error:(NSError*)error
{
    NSLog(@"subscribe fail");
}

- (void)xmppClent:(id<HJXmppClient>)sender
didFailToReceiveMessageWithError:(NSError*)error {
    
    NSLog(@"message fail");
}

- (void)xmppClentDidCloseConnection:(id<HJXmppClient>)sender {
    
    NSLog(@"close");
}

@end
