//
//  HJUrlSessionImageUploader.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/17/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJUrlSessionImageUploader.h"
#import "HJXmppChatAttachmentJsonParser.h"

typedef void (^NSUrlSessionUploadCompletedBlock)(NSData *data, NSURLResponse *response, NSError *error);

@implementation HJUrlSessionImageUploader
{
    NSString* _schemeAndHostAndPort;
    NSString* _token;
    
    NSURLSession* _session;
    NSURLSessionUploadTask* _upload;
}
- (instancetype)initWithHost:(NSString*)schemeAndHostAndPort
                   authToken:(NSString*)token
                  urlSession:(NSURLSession*)session
{
    NSParameterAssert(nil != schemeAndHostAndPort);
    NSParameterAssert(nil != token);
    NSParameterAssert(nil != session);
    
    self = [super init];
    if (nil == self)
    {
        return nil;
    }
    
    self->_schemeAndHostAndPort = schemeAndHostAndPort;
    self->_token                = token;
    self->_session              = session;
    
    return self;
}

- (void)uploadAtachment:(NSData*)attachmentBinary
     withSuccessHandler:(HJAttachmentUploadSuccessBlock)onAttachmentUploadedBlock
           errorHandler:(HJAttachmentUploadErrorBlock)onAttachmentUploadNetworkError
{
    NSParameterAssert(nil == self->_upload);
    
    NSParameterAssert(nil != attachmentBinary);
    NSParameterAssert(nil != onAttachmentUploadedBlock);
    NSParameterAssert(nil != onAttachmentUploadNetworkError);
    
    
    NSString* rawUploadUrl = [self uploadUrl];
    NSURL* url = [NSURL URLWithString: rawUploadUrl];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: url];
    {
        request.HTTPMethod = @"POST";
        
        [request setValue: [self tokenHeaderValue]
       forHTTPHeaderField: @"Authorization"];
    }
    

    NSUrlSessionUploadCompletedBlock onDataLoaded =
    ^void(NSData *data, NSURLResponse *response, NSError *error)
    {
        if (nil != error)
        {
            onAttachmentUploadNetworkError(error);
        }
        else
        {
            // TODO : parse on background thread if needed
            NSError* parseError = nil;
            id<HJXmppChatAttachment> result = [HJXmppChatAttachmentJsonParser parseAttachmentResponse: data
                                                                                                error: &parseError];
            
            if (nil == result)
            {
                onAttachmentUploadNetworkError(parseError);
            }
            else
            {
                onAttachmentUploadedBlock(result);
            }
        }
    };
    
    self->_upload = [self->_session uploadTaskWithRequest: request
                                                 fromData: attachmentBinary
                                        completionHandler: onDataLoaded];
    [self->_upload resume];
}

- (NSString*)uploadUrl
{
    NSString* result = [self->_schemeAndHostAndPort stringByAppendingString: @"assistant/attachments"];
    return result;
}

- (NSString*)tokenHeaderValue
{
    NSString* result = [@"Bearer " stringByAppendingString: self->_token];
    return result;
}


@end
