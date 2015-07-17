//
//  HJMockSuccessAttachmentUploader.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/17/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJMockSuccessAttachmentUploader.h"

#import "HJXmppChatAttachmentPOD.h"


@implementation HJMockSuccessAttachmentUploader

- (void)uploadAtachment:(NSData*)attachmentBinary
     withSuccessHandler:(HJAttachmentUploadSuccessBlock)onAttachmentUploadedBlock
           errorHandler:(HJAttachmentUploadErrorBlock)onAttachmentUploadNetworkError

{
    HJXmppChatAttachmentPOD* result = [HJXmppChatAttachmentPOD new];
    {
        result.fileName = @"IMG_0084.PNG";
        result.rawImageSize = @"80x120";
        result.fullSizeImageUrl = @"http://cdn-dev.hjdev/objects/IMpRM0dalB_IMG_0084.PNG";
        result.thumbnailUrl = @"http://cdn-dev.hjdev/objects/IMpRM0dalB_thumb_IMG_0084.PNG";
    }

    onAttachmentUploadedBlock(result);
}

@end
