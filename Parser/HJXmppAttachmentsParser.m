//
//  HJXmppAttachmentsParser.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/17/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJXmppAttachmentsParser.h"

#import "HJXmppChatAttachment.h"
#import "HJXmppChatAttachmentPOD.h"


@implementation HJXmppAttachmentsParser

+ (NSArray*)parseAttachmentsOfMessage:(id)xmlMessage
{
    NSXMLElement* castedRawMessage = (NSXMLElement*)xmlMessage;
    
    NSArray* attachmentElements = [castedRawMessage elementsForName: @"attachment"];
    if (0 == [attachmentElements count])
    {
        // Checking explicitly for better debugging experience
        return nil;
    }
    
    
    LINQSelector parseAttachmentBlock = ^id<HJXmppChatAttachment>(NSXMLElement* singleAttachmentElement)
    {
        return [self parseSingleAttachmentElement: singleAttachmentElement];
    };
    NSArray* result = [attachmentElements linq_select: parseAttachmentBlock];
    
    return result;
}

+ (id<HJXmppChatAttachment>)parseSingleAttachmentElement:(id)xmlAttachmentElement
{
    NSXMLElement* castedRawAttachment = (NSXMLElement*)xmlAttachmentElement;
    
    NSString* rawImageSize = [[castedRawAttachment attributeForName: @"size"     ] stringValue];
    NSString* fileName     = [[castedRawAttachment attributeForName: @"file_name"] stringValue];
    NSString* fullSizeUrl  = [[castedRawAttachment attributeForName: @"url"      ] stringValue];
    NSString* thumbnailUrl = [[castedRawAttachment attributeForName: @"thumb_url"] stringValue];
    
    HJXmppChatAttachmentPOD* result = [HJXmppChatAttachmentPOD new];
    {
        result.rawImageSize     = rawImageSize;
        result.fileName         = fileName    ;
        result.fullSizeImageUrl = fullSizeUrl ;
        result.thumbnailUrl     = thumbnailUrl;
    }
    
    return result;
}

@end

/*
<message
    from="071515_142949_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)"
    to="user+11952@xmpp-dev.healthjoy.com/2786719646143761414240863"
    type="groupchat"
    xmlns="jabber:client"
    xmlns:stream="http://etherx.jabber.org/streams"
    version="1.0">
        <body>Message and two images</body>

        <attachment
            file_name="IMG_0050.PNG"
            size="67x120"
            thumb_url="http://cdn-dev.hjdev/objects/RjSIVPeoW5_thumb_IMG_0050.PNG"
            url="http://cdn-dev.hjdev/objects/RjSIVPeoW5_IMG_0050.PNG"/>

        <attachment
            file_name="IMG_0084.PNG"
            size="80x120"
            thumb_url="http://cdn-dev.hjdev/objects/S3ztL9p7vq_thumb_IMG_0084.PNG"
            url="http://cdn-dev.hjdev/objects/S3ztL9p7vq_IMG_0084.PNG"/>

        <html xmlns="http://jabber.org/protocol/xhtml-im">
            <body>
                <p>Message and two images</p>
 
                <a href="http://cdn-dev.hjdev/objects/RjSIVPeoW5_IMG_0050.PNG">
                    http://cdn-dev.hjdev/objects/RjSIVPeoW5_IMG_0050.PNG
                </a>
 
                <a href="http://cdn-dev.hjdev/objects/S3ztL9p7vq_IMG_0084.PNG">
                    http://cdn-dev.hjdev/objects/S3ztL9p7vq_IMG_0084.PNG
                </a>
            </body>
        </html>
</message>
*/