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
        NSXMLElement* castedRawMessage = (NSXMLElement*)element;
        NSArray* finElementArray = [castedRawMessage elementsForName: @"fin"];
        
        isFinMessage = (0 == [finElementArray count]);
    }
    
    return isFinMessage;
}

+ (BOOL)isHistoryMessage:(id<XMPPMessageProto>)element
{
    NSXMLElement* castedRawMessage = (NSXMLElement*)element;
    NSArray* resultNodes = [castedRawMessage elementsForName: @"result"];
    
    return (0 != [resultNodes count]);
}


@end
