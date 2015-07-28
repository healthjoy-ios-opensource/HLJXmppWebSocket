//
//  HJValidButEmptyAttachmentResponseError.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/28/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJValidButEmptyAttachmentResponseError.h"

@implementation HJValidButEmptyAttachmentResponseError

-(instancetype)init
{
    self = [super initWithDomain: @"com.healthjoy.xmpp.attachment.upload.empty-array"
                            code: 1
                        userInfo: nil];
    
    return self;
}

-(instancetype)initWithDomain:(NSString *)domain
                         code:(NSInteger)code
                     userInfo:(NSDictionary *)dict
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}


@end
