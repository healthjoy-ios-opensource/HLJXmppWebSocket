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


typedef void(^HJAttachmentUploadSuccessBlock)(id<HJXmppChatAttachment> attachment);
typedef void(^HJAttachmentUploadErrorBlock)(NSError* error);


@protocol HJAttachmentUploader <NSObject>

- (void)uploadAtachment:(UIImage*)attachment
     withSuccessHandler:(HJAttachmentUploadSuccessBlock)onAttachmentUploadedBlock
           errorHandler:(HJAttachmentUploadErrorBlock)onAttachmentUploadNetworkError;

@end
