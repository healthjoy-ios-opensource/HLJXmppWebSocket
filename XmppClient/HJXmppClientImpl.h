//
//  HJXmppClientImpl.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/9/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HLJXmppWebSocket/XmppClient/HJXmppClient.h>

@protocol XMPPParserProto;
@protocol HJAttachmentUploader;
@protocol HJLogger;
typedef id<XMPPParserProto>(^XmppParserBuilderBlock)();

@interface HJXmppClientImpl : NSObject<HJXmppClient>

+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

/**
 
 @param transport SRWebSocket instance

 @param xmppHost Same for GH and HJ products
 xmpp-dev.healthjoy.com
 xmpp-stage.healthjoy.com
 xmpp.healthjoy.com
 
 
 @param accessToken See OAuth docs for details 
 */
- (instancetype)initWithTransport:(id<HJTransportForXmpp>)transport
                attachmentsUpload:(id<HJAttachmentUploader>)attachmentUpload
                             host:(NSString*)xmppHost
                      accessToken:(NSString*)accessToken
                           logger:(id<HJLogger>)logger
NS_DESIGNATED_INITIALIZER
NS_REQUIRES_SUPER
;

@property (nonatomic, weak) id<HJXmppClientDelegate> listenerDelegate;

@end
