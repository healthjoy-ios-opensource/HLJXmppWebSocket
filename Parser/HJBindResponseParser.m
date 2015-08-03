//
//  HJBindResponseParser.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJBindResponseParser.h"

@implementation HJBindResponseParser

+ (BOOL)isResponseToSkip:(id)nsXmlElement
{
    NSParameterAssert([nsXmlElement isKindOfClass: [NSXMLElement class]]);
    
    NSXMLElement* element = (NSXMLElement*)nsXmlElement;
    NSString* elementName = [element name];
    
    BOOL result = (![elementName isEqualToString: @"iq"]);
    
    return result;
}

+ (BOOL)isSuccessfulBindResponse:(id)nsXmlElement
{
    NSParameterAssert([nsXmlElement isKindOfClass: [NSXMLElement class]]);
    NSXMLElement* element = (NSXMLElement*)nsXmlElement;
    XMPPIQ* responseIq = [XMPPIQ iqFromElement: element];
    
    if ([responseIq isErrorIQ])
    {
        return NO;
    }
    else if ([responseIq isResultIQ])
    {
        NSXMLNode* idAttribute = [element attributeForName: @"id"];
        NSString* idValue = [idAttribute stringValue];
        
        return [idValue isEqualToString: @"_bind_auth_2"];
    }
    else
    {
        return NO;
    }
}

+ (NSString*)jidFromBindResponse:(id)nsXmlElement
{
    NSParameterAssert([nsXmlElement isKindOfClass: [NSXMLElement class]]);
    NSXMLElement* element = (NSXMLElement*)nsXmlElement;
    XMPPIQ* responseIq = [XMPPIQ iqFromElement: element];
    
    NSXMLElement* bindElement = [responseIq childElement];
    NSXMLElement* jidElement = [[bindElement children] firstObject];
    
    NSString* rawJid = [jidElement stringValue];
    
    return rawJid;
}

@end


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


