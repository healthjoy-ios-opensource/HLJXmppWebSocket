//
//  HJUrlSessionImageUploader.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/17/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJUrlSessionImageUploader.h"

@implementation HJUrlSessionImageUploader
{
    NSString* _schemeAndHostAndPort;
    NSString* _token;
}
- (instancetype)initWithHost:(NSString*)schemeAndHostAndPort
                   authToken:(NSString*)token
{
    self = [super init];
    if (nil == self)
    {
        return nil;
    }
    
    self->_schemeAndHostAndPort = schemeAndHostAndPort;
    self->_token                = token;
    
    return self;
}

- (void)uploadAtachment:(NSData*)attachmentBinary
     withSuccessHandler:(HJAttachmentUploadSuccessBlock)onAttachmentUploadedBlock
           errorHandler:(HJAttachmentUploadErrorBlock)onAttachmentUploadNetworkError
{
    NSAssert(NO, @"not implemented");
}

@end
