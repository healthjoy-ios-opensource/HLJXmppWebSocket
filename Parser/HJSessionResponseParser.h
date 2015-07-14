//
//  HJSessionResponseParser.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HJSessionResponseParser : NSObject

+ (BOOL)isResponseToSkip:(id)nsXmlElement;
+ (BOOL)isSuccessfulSessionResponse:(id)nsXmlElement;

@end
