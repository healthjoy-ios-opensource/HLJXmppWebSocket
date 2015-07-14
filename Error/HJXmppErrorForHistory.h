//
//  HJXmppErrorForHistory.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/14/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HJXmppErrorForHistory : NSError

+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;
-(instancetype)initWithDomain:(NSString *)domain
                         code:(NSInteger)code
                     userInfo:(NSDictionary *)dict
NS_UNAVAILABLE;

-(instancetype)initWithErrorCode:(NSString*)errorCode
NS_DESIGNATED_INITIALIZER
NS_REQUIRES_SUPER
__attribute__((nonnull));

@property (nonatomic, readonly) NSString* xmppErrorCode;

@end
