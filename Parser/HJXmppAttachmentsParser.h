//
//  HJXmppAttachmentsParser.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/17/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HJXmppAttachmentsParser : NSObject

+ (NSArray*)parseAttachmentsOfMessage:(id)xmlMessage;

@end
