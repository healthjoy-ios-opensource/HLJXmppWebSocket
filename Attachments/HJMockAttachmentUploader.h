//
//  HJMockAttachmentUploader.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/16/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJAttachmentUploader.h"

@interface HJMockAttachmentUploader : NSObject<HJAttachmentUploader>

- (void)uploadAtachment:(NSData*)attachmentBinary
     withSuccessHandler:(HJAttachmentUploadSuccessBlock)onAttachmentUploadedBlock
           errorHandler:(HJAttachmentUploadErrorBlock)onAttachmentUploadNetworkError;

- (void)simulateSuccessWithResult:(id<HJXmppChatAttachment>)result;
- (void)simulateError:(NSError*)error;

@end
