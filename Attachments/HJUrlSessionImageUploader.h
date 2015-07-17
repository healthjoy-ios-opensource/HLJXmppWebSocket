//
//  HJUrlSessionImageUploader.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/17/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HLJXmppWebSocket/Attachments/HJAttachmentUploader.h>

@interface HJUrlSessionImageUploader : NSObject<HJAttachmentUploader>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithHost:(NSString*)schemeAndHostAndPort
                   authToken:(NSString*)token
NS_REQUIRES_SUPER
NS_DESIGNATED_INITIALIZER
__attribute__((nonnull));

@end
