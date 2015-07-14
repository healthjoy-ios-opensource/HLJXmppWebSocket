//
//  HJHistoryFailParser.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 14/07/2015.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJHistoryFailParser.h"

#import "HJXmppErrorForHistory.h"

@implementation HJHistoryFailParser

+ (NSError*)errorForFailedHistoryResponse:(id<XmppIqProto>)element;
{
    NSXMLElement* errorElement = [element childErrorElement];
    NSString* rawErrorCode = [[errorElement attributeForName: @"code"] stringValue];
    
    HJXmppErrorForHistory* error = [[HJXmppErrorForHistory alloc] initWithErrorCode: rawErrorCode];
    
    return error;
}

+ (NSString*)roomIdForFailedHistoryResponse:(id<XmppIqProto>)element;
{
    NSString* roomIdFromResponse = nil;
    {
        NSXMLElement* queryElement = [element childElement];
        NSXMLElement* xElement = [[queryElement elementsForName: @"x"] firstObject];
        NSArray* fields = [xElement elementsForName: @"field"];
        
        LINQCondition withFieldPredicate = ^BOOL(NSXMLElement* singleField)
        {
            NSString* attribtueContent = [[singleField attributeForName: @"var"] stringValue];
            BOOL result = [attribtueContent isEqualToString: @"with"];
            
            return result;
            
        };
        
        NSXMLElement* withField = [fields linq_firstOrNil: withFieldPredicate];
        NSXMLElement* withValueElement = [[withField elementsForName: @"value"] firstObject];
        
        roomIdFromResponse = [withValueElement stringValue];
    }

    return roomIdFromResponse;
}


@end
