//
//  HJRandomizerImpl.h
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/14/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJRandomizerForXmpp.h"

@interface HJRandomizerImpl : NSObject<HJRandomizerForXmpp>

/**
 @return A random integer number with 7 digits.
 */
- (NSString*)getRandomIdForStanza;

@end
