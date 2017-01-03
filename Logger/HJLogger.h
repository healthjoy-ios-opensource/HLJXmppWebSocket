//
//  HJLogger.h
//  HLJXmppWebSocket
//
//  Created by Mark Prutskiy on 8/1/16.
//  Copyright © 2016 healthjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSManagedObjectContext;

@protocol HJLogger <NSObject>

- (void)setDebugFlag:(NSManagedObjectContext *)context;
- (void)log:(NSString *)logStr;

@end
