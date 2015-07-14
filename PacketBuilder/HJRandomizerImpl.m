//
//  HJRandomizerImpl.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/14/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJRandomizerImpl.h"

@implementation HJRandomizerImpl

- (NSString*)getRandomIdForStanza {
    
    u_int32_t rawResult = arc4random_uniform(10000000);
    NSNumber* boxedResult = @(rawResult);
    
    NSString* result = [boxedResult descriptionWithLocale: nil];
    return result;
}

@end
