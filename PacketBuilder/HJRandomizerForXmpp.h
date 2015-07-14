//
//  HJRandomizerForXmpp.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/14/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HJRandomizerForXmpp <NSObject>

- (NSString*)getRandomIdForStanza;

@end
