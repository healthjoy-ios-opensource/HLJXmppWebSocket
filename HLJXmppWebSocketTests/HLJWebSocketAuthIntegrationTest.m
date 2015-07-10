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

@interface HLJWebSocketAuthIntegrationTest : XCTestCase
@end


@implementation HLJWebSocketAuthIntegrationTest
{
    HJXmppClientImpl* _sut      ;
    SRWebSocket     * _webSocket;
}


- (void)setUp {
    [super setUp];

    static NSString* const jid = @"070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)";

    
    // !!! needs manual updating
    static NSString* const accessToken = @"dXNlcisxMTk1MkB4bXBwLWRldi5oZWFsdGhqb3kuY29tAHVzZXIrMTE5NTIAN3FKWjJIOFQ5V0FtWTNCU2M1Qkk3WVBOVXk3RG5E";
    
    NSURL* webSocketUrl = [NSURL URLWithString: @"wss://gohealth-dev.hjdev/ws-chat/"];
    self->_webSocket = [[SRWebSocket alloc] initWithURL: webSocketUrl];
    
    XMPPParser* parser = [[XMPPParser alloc] initWithDelegate: nil
                                                delegateQueue: NULL];
    
    self->_sut = [[HJXmppClientImpl alloc] initWithTransport: (id<HJTransportForXmpp>)self->_webSocket
                                                  xmppParser: parser
                                                        host: @"xmpp-dev.healthjoy.com"
                                                 accessToken: accessToken
                                               userJidString: jid];
}

- (void)tearDown {
    
    [self->_sut disconnect];
    [self->_webSocket close];
    
    self->_sut = nil;
    self->_webSocket = nil;
    
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

@end
