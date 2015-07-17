//
//  HJMockErrorAttachmentUploader.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 17/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJAttachmentUploader.h"

@interface HJMockErrorAttachmentUploader : NSObject<HJAttachmentUploader>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithMockError:(NSError*)error
NS_DESIGNATED_INITIALIZER
NS_REQUIRES_SUPER
__attribute__((nonnull));

@end
