//
//  HJXmppErrorForHistory.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/14/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJXmppErrorForHistory.h"

@implementation HJXmppErrorForHistory

-(instancetype)initWithErrorCode:(NSString*)errorCode
{
    self = [super initWithDomain: @"com.healthjoy.xmpp-ws.history"
                            code: 1
                        userInfo: nil];
    if (nil == self)
    {
        return nil;
    }
    
    self->_xmppErrorCode = errorCode;
    
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
