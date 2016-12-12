//
//  SRWebSocketDelegate.h
//  HLJXmppWebSocket
//
//  Created by Mark Prutskiy on 12/12/16.
//  Copyright © 2016 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SRWebSocketDelegate;

@protocol SRWebSocketProtocol <NSObject>

- (NSInteger)readyState;

- (void)open;

- (void)close;
- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;

// Send a UTF8 String or Data.
- (void)send:(id)data;

-(id<SRWebSocketDelegate>)delegate;
-(void)setDelegate:(id<SRWebSocketDelegate>)value;

@end
