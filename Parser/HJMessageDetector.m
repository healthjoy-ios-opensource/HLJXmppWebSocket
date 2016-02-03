//
//  HJMessageDetector.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJMessageDetector.h"

@implementation HJMessageDetector

+ (BOOL)isFinMessage:(id<XMPPMessageProto>)element
{
    // Last message
    //
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
    
    
    BOOL isFinMessage = NO;
    {
        // TODO : remove cast
        NSParameterAssert([element isKindOfClass: [NSXMLElement class]]);
        NSXMLElement* castedRawMessage = (NSXMLElement*)element;
        
        NSArray* finElementArray = [castedRawMessage elementsForName: @"fin"];
        
        isFinMessage = (0 != [finElementArray count]);
    }
    
    return isFinMessage;
}

+ (BOOL)isHistoryMessage:(id<XMPPMessageProto>)element
{
    NSParameterAssert([element isKindOfClass: [NSXMLElement class]]);
    NSXMLElement* castedRawMessage = (NSXMLElement*)element;
    
    NSArray* resultNodes = [castedRawMessage elementsForName: @"result"];
    
    return (0 != [resultNodes count]);
}

+ (BOOL)isLiveMessage:(id<XMPPMessageProto>)element
{
    NSParameterAssert([element isKindOfClass: [NSXMLElement class]]);
    NSXMLElement* castedRawMessage = (NSXMLElement*)element;
    
    NSArray* archivedNodes = [castedRawMessage elementsForName: @"archived"];
    
    return (0 != [archivedNodes count]);
}

+ (BOOL)isCloseChatMessage:(id<XMPPMessageProto>)element
{
    NSString* bodyMessage = [element body];
    static NSString* const CLOSE_CHAT_MESSAGE_ID = @"!close_chat";
    
    BOOL result = [bodyMessage isEqualToString: CLOSE_CHAT_MESSAGE_ID];
    return result;
    
//    <message from="082015_144829_qatest_qatest_general_question@conf.xmpp.healthjoy.com/System Message" to="user+33254@xmpp.healthjoy.com/1039786960144082112156871" type="groupchat" xml:lang="en" id="_close" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0"><archived by="082015_144829_qatest_qatest_general_question@conf.xmpp.healthjoy.com" xmlns="urn:xmpp:mam:tmp" id="1440082146068600"/></message>

}

@end
