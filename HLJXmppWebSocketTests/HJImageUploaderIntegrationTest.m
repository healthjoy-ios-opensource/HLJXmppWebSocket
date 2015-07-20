//
//  HJImageUploaderIntegrationTest.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/20/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "HJUrlSessionImageUploader.h"

@interface HJImageUploaderIntegrationTest : XCTestCase
@end


@implementation HJImageUploaderIntegrationTest
{
    NSURLSession* _sharedSession;
    HJUrlSessionImageUploader* _sut;
    NSData* _imageToSend;
    NSBundle* _mainBundle;
    
    id<HJXmppChatAttachment> _attachmentUploadResponse;
    NSError* _uploadError;
}


- (void)setUp {
    [super setUp];

    NSBundle* mainBundle = [NSBundle bundleForClass: [self class]];
    self->_mainBundle = mainBundle;
    
    
    NSString* filePath = [mainBundle pathForResource: @"monkey-selfie"
                                              ofType: @"jpg"];
    self->_imageToSend = [NSData dataWithContentsOfFile: filePath];
    
    
    
    self->_sharedSession = [NSURLSession sharedSession];
    self->_sut = [[HJUrlSessionImageUploader alloc] initWithHost: @"https://staging.healthjoy.com/"
                                                       authToken: @"zVlhUDJVVlXVgk8x0fek9Iv213n8ul"
                                                      urlSession: self->_sharedSession];
}

- (void)tearDown {

    self->_mainBundle = nil;
    self->_sharedSession = nil;
    self->_imageToSend = nil;
    self->_sut = nil;
    [super tearDown];
}

- (void)testSuccessfulUpload
{
    XCTestExpectation* onUploadCompleted = [self expectationWithDescription: @"Upload ended"];
    
    __weak HJImageUploaderIntegrationTest* weakSelf = self;
    HJAttachmentUploadSuccessBlock onLoadSuccessBlock = ^void(id<HJXmppChatAttachment> attachment)
    {
        HJImageUploaderIntegrationTest* strongSelf = weakSelf;
        if (nil != strongSelf)
        {
            strongSelf->_attachmentUploadResponse = attachment;
        }
        
        [onUploadCompleted fulfill];
    };
    HJAttachmentUploadErrorBlock onLoadErrorBlock = ^void(NSError* error)
    {
        HJImageUploaderIntegrationTest* strongSelf = weakSelf;
        if (nil != strongSelf)
        {
            strongSelf->_uploadError = error;
        }
        
        [onUploadCompleted fulfill];
    };
    
    [self->_sut uploadAtachment: self->_imageToSend
             withSuccessHandler: [onLoadSuccessBlock copy]
                   errorHandler: [onLoadErrorBlock   copy]];
    [self waitForExpectationsWithTimeout: 300.f
                                 handler: nil];
    
    XCTAssertNotNil(self->_attachmentUploadResponse);
    XCTAssertNil(self->_uploadError);
}

@end
