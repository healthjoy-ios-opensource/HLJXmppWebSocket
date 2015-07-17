//
//  HJMockErrorAttachmentUploader.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 17/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJMockErrorAttachmentUploader.h"

@implementation HJMockErrorAttachmentUploader
{
    NSError* _error;
}

- (instancetype)initWithMockError:(NSError*)error
{
    self = [super init];
    if (nil == self)
    {
        return nil;
    }
    
    self->_error = error;
    
    return self;
}

- (void)uploadAtachment:(NSData*)attachmentBinary
     withSuccessHandler:(HJAttachmentUploadSuccessBlock)onAttachmentUploadedBlock
           errorHandler:(HJAttachmentUploadErrorBlock)onAttachmentUploadNetworkError
{
    onAttachmentUploadNetworkError(self->_error);
}

@end
