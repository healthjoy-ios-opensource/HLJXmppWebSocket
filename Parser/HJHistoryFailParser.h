//
//  HJHistoryFailParser.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XmppIqProto;

@interface HJHistoryFailParser : NSObject

+ (NSError*)errorForFailedHistoryResponse:(id<XmppIqProto>)element;
+ (NSString*)roomIdForFailedHistoryResponse:(id<XmppIqProto>)element;

@end
