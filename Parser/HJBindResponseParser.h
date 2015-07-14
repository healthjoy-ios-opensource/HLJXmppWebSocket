//
//  HJBindResponseParser.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HJBindResponseParser : NSObject

+ (BOOL)isResponseToSkip:(id)nsXmlElement;
+ (BOOL)isSuccessfulBindResponse:(id)nsXmlElement;
+ (NSString*)jidFromBindResponse:(id)nsXmlElement;

@end
