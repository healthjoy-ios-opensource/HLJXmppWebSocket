//
//  HJXmppSessionResponseError.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJXmppSessionResponseError.h"

@implementation HJXmppSessionResponseError

-(instancetype)init
{
    self = [super initWithDomain: @"com.healthjoy.xmpp-ws.auth.session"
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
