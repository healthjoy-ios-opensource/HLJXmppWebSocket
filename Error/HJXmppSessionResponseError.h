//
//  HJXmppSessionResponseError.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HLJXmppWebSocket/Error/HJXmppErrorBase.h>

@interface HJXmppSessionResponseError : HJXmppErrorBase

-(instancetype)init
NS_DESIGNATED_INITIALIZER
NS_REQUIRES_SUPER;


-(instancetype)initWithDomain:(NSString *)domain
                         code:(NSInteger)code
                     userInfo:(NSDictionary *)dict
NS_UNAVAILABLE;

@end
