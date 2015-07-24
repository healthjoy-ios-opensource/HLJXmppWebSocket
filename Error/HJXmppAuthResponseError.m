//
//  HJXmppAuthResponseError.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/24/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJXmppAuthResponseError.h"

@implementation HJXmppAuthResponseError

-(instancetype)init
{
    self = [super initWithDomain: @"com.healthjoy.xmpp-ws.auth.auth"
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
