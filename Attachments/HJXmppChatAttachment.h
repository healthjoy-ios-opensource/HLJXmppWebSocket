//
//  HJXmppChatAttachment.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/16/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

/*
<attachment
file_name='tmp.png'
size='120x90'
thumb_url='http://cdn-dev.hjdev/objects/HNkqNvh5ca_thumb_tmp.png'
url='http://cdn-dev.hjdev/objects/HNkqNvh5ca_tmp.png'/>
*/


/**
 Similar to HJAttachment + single HJAttachmentThumbnail from HealthJoyChat.xcodeproj
 */
@protocol HJXmppChatAttachment <NSObject>


#pragma mark - HJAttachment
/*
 */
- (NSString*)fileName;
- (NSString*)fullSizeImageUrl;


#pragma mark - HJAttachmentThumbnail
- (NSString*)thumbnailUrl;

/**
 Received from the back end
 */
-(NSString*)rawImageSize;

/**
 Parsed for convenience
 */
-(CGSize)imageSize;


@end
