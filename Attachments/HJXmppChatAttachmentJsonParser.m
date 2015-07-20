//
//  HJXmppChatAttachmentJsonParser.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/20/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJXmppChatAttachmentJsonParser.h"
#import "HJXmppChatAttachmentPOD.h"


@implementation HJXmppChatAttachmentJsonParser

+ (id<HJXmppChatAttachment>)parseAttachmentResponse:(NSData*)input
                                              error:(NSError**)outError
{
    NSParameterAssert(nil != input);
    NSParameterAssert(nil != outError);

    NSString* logInput = [[NSString alloc] initWithData: input
                                               encoding: NSUTF8StringEncoding];
    NSLog(@"%@", logInput);
    
    id rawInput = [NSJSONSerialization JSONObjectWithData: input
                                                  options:(NSJSONReadingOptions)0
                                                    error: outError];
    
    // TODO : use safe casts
    NSDictionary* rawRootObject = (NSDictionary*)rawInput;
    NSArray* rawAttachmentObjects = (NSArray*)rawRootObject[@"attachments"];
    NSParameterAssert(1 == [rawAttachmentObjects count]);
    
    NSDictionary* rawResult = (NSDictionary*)[rawAttachmentObjects firstObject];
    HJXmppChatAttachmentPOD* result = [HJXmppChatAttachmentPOD new];
    {
        result.rawImageSize     = rawResult[@"size"     ];
        result.fileName         = rawResult[@"file_name"];
        result.thumbnailUrl     = rawResult[@"thumb_url"];
        result.fullSizeImageUrl = rawResult[@"url"      ];
    }
    
    return result;
}


@end


/*
{
    "attachments": [
                    {
                        "file_name": "IMG_0085.PNG",
                        "size": "80x120",
                        "thumb_url": "http://cdn-dev.hjdev/objects/Cy0M9zQuTZ_thumb_IMG_0085.PNG",
                        "url": "http://cdn-dev.hjdev/objects/Cy0M9zQuTZ_IMG_0085.PNG"
                    }
                    ]
}
*/

