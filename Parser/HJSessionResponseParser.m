//
//  HJSessionResponseParser.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJSessionResponseParser.h"

@implementation HJSessionResponseParser

+ (BOOL)isResponseToSkip:(id)nsXmlElement
{
    NSParameterAssert([nsXmlElement isKindOfClass: [NSXMLElement class]]);
    NSXMLElement* element = (NSXMLElement*)nsXmlElement;
    
    NSString* elementName = [element name];
    BOOL result = (![elementName isEqualToString: @"iq"]);
    
    return result;
}

+ (BOOL)isSuccessfulSessionResponse:(id)nsXmlElement
{
    NSParameterAssert([nsXmlElement isKindOfClass: [NSXMLElement class]]);
    NSXMLElement* element = (NSXMLElement*)nsXmlElement;
    
    XMPPIQ* parsedIq = [XMPPIQ iqFromElement: element];
    if ([parsedIq isErrorIQ])
    {
        return NO;
    }
    else if ([parsedIq isResultIQ])
    {
        return [[parsedIq elementID] isEqualToString: @"_session_auth_2"];
    }
    else
    {
        return NO;
    }
}

@end
