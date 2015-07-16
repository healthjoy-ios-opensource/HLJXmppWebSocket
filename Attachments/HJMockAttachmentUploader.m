//
//  HJMockAttachmentUploader.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/16/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJMockAttachmentUploader.h"

@implementation HJMockAttachmentUploader
{
    HJAttachmentUploadSuccessBlock _onAttachmentUploadedBlock     ;
    HJAttachmentUploadErrorBlock   _onAttachmentUploadNetworkError;
}


- (void)uploadAtachment:(NSData*)attachmentBinary
     withSuccessHandler:(HJAttachmentUploadSuccessBlock)onAttachmentUploadedBlock
           errorHandler:(HJAttachmentUploadErrorBlock)onAttachmentUploadNetworkError
{
    self->_onAttachmentUploadedBlock      = [onAttachmentUploadedBlock      copy];
    self->_onAttachmentUploadNetworkError = [onAttachmentUploadNetworkError copy];
}

- (void)simulateSuccessWithResult:(id<HJXmppChatAttachment>)result
{
    self->_onAttachmentUploadedBlock(result);
}

- (void)simulateError:(NSError*)error
{
    self->_onAttachmentUploadNetworkError(error);
}

@end
