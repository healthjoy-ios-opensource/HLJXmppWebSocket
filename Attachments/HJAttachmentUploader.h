//
//  HJAttachmentUploader.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/16/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>


@class UIImage;
@protocol HJXmppChatAttachment;


typedef void(^HJAttachmentUploadSuccessBlock)(NSArray* attachments);
typedef void(^HJAttachmentUploadErrorBlock)(NSError* error);


@protocol HJAttachmentUploader <NSObject>

- (void)uploadAtachments:(NSArray*)attachments
     withSuccessHandler:(HJAttachmentUploadSuccessBlock)onAttachmentUploadedBlock
           errorHandler:(HJAttachmentUploadErrorBlock)onAttachmentUploadNetworkError;

@end
