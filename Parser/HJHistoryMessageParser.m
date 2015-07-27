//
//  HJHistoryMessageParser.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJHistoryMessageParser.h"

@implementation HJHistoryMessageParser

+ (id<XMPPMessageProto>)unwrapHistoryMessage:(id<XMPPMessageProto>)element
{
    NSXMLElement* castedRawMessage = (NSXMLElement*)element;
    NSXMLElement* resultNode = [[castedRawMessage elementsForName: @"result"] firstObject];
    NSXMLElement* forwardedNode = [[resultNode elementsForName: @"forwarded"] firstObject];
    
    
    NSXMLElement* rawResult = [[forwardedNode elementsForName: @"message"] firstObject];
    XMPPMessage* result = [XMPPMessage messageFromElement: rawResult];
    
    NSArray* attachments = [rawResult elementsForName: @"attachment"];
    BOOL isMessageWithContent =
        (nil != [result body]) ||
        (0   != [attachments count]);
    
    
    
    BOOL isMessageHasTimestamp = (nil != [XMPPMessageTimestampParser parseTimestampFromXmlElement: result]);
    
    NSDate* elementNodeTimestamp = [XMPPMessageTimestampParser parseTimestampFromXmlElement: element];
    BOOL isElementHasTimestamp = (nil != elementNodeTimestamp);
    
    NSDate* forwardedNodeTimestamp = [XMPPMessageTimestampParser parseTimestampFromXmlElement: forwardedNode];
    BOOL isElementForwardedHasTimestamp = (nil != forwardedNodeTimestamp);
    
    if (nil == result)
    {
        return element;
    }
    else if (isMessageWithContent)
    {
        if (!isMessageHasTimestamp)
        {
            if (isElementHasTimestamp)
            {
                result.timestamp = elementNodeTimestamp;
            }
            else if (isElementForwardedHasTimestamp)
            {
                result.timestamp = forwardedNodeTimestamp;
            }
        }

        return result;
    }
    else
    {
        return [self unwrapHistoryMessage: result];
    }
}

@end



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

