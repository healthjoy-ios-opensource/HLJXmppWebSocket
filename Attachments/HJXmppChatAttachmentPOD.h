//
//  HJXmppChatAttachmentPOD.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/17/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJXmppChatAttachment.h"

@interface HJXmppChatAttachmentPOD : NSObject<HJXmppChatAttachment>

#pragma mark - HJAttachment
@property (nonatomic, copy) NSString* fileName;
@property (nonatomic, copy) NSString* fullSizeUrl;

@property (nonatomic, assign) BOOL isFile;

#pragma mark - HJAttachmentThumbnail
@property (nonatomic, copy) NSString* thumbnailUrl;

/**
 Received from the back end
 */
@property (nonatomic, copy) NSString* rawSize;

/**
 Not computed from rawImageSize.
 Throws an exception.
 */
@property (nonatomic, readonly) CGSize imageSize;

@end
