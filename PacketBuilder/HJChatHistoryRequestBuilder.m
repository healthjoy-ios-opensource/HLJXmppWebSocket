//
//  HJChatHistoryRequestBuilder.m
//  HLJXmppWebSocket
//
//  Created by Oleksandr Dodatko on 7/14/15.
//  Copyright (c) 2015 healthjoy. All rights reserved.
//

#import "HJChatHistoryRequestBuilder.h"

#import "HJRandomizerForXmpp.h"
#import "HJChatHistoryRequest.h"

@implementation HJChatHistoryRequestBuilder
{
    id<HJRandomizerForXmpp> _randomizer;
}

- (instancetype)initWithRandomizer:(id<HJRandomizerForXmpp>)randomizer
{
    NSParameterAssert(nil != randomizer);
    
    self = [super init];
    if (nil == self)
    {
        return nil;
    }
    
    self->_randomizer = randomizer;
    
    return self;
}

- (id<HJChatHistoryRequestProto>)buildRequestForRoom:(NSString*)roomJid
                                               limit:(NSUInteger)maxMessageCount
{
    NSString* strMaxMessageCount = [@(maxMessageCount) descriptionWithLocale: nil];
    
    NSString* messageFormat =
    @"<iq"
    @" type='set'"
    @" id='%@'" //<!-- Random -->
    @">"
    @"<query "
    @" xmlns='urn:xmpp:mam:0'"
    @" queryid='%@'>" //<!-- Random -->
    @"<x xmlns='jabber:x:data' type='submit'>"
    @"<field var='FORM_TYPE'>"
    @"<value>urn:xmpp:mam:0</value>"
    @"</field>"
    @"<field var='withroom'>" // [dev, "withroom"], [prod : "with"]
    @"<value>%@</value>" // roomJid
    @"</field>"
    @"<field var='start'>"
    @"<value>1970-01-01T00:00:00Z</value>" // <!-- The service did not exist back in 1970 -->
    @"</field>"
    @"</x>"
    @"<set xmlns='http://jabber.org/protocol/rsm'>"
    @"<max>%@</max>" // No way to request everything. Using a large constant
    @"</set>"
    @"</query>"
    @"</iq>";
    
    NSString* randomIdForIq    = [self->_randomizer getRandomIdForStanza];
    NSString* randomIdForQuery = [self->_randomizer getRandomIdForStanza];
    
    NSString* request =
        [NSString stringWithFormat: messageFormat,
            randomIdForIq     ,
            randomIdForQuery  ,
            roomJid           ,
            strMaxMessageCount];
    
    HJChatHistoryRequest* result = [HJChatHistoryRequest new];
    {
        result.dataToSend = request         ;
        result.idForIq    = randomIdForIq   ;
        result.idForQuery = randomIdForQuery;
    }
    
    return result;
}

- (id<HJChatHistoryRequestProto>)buildUnlimitedRequestForRoom:(NSString*)roomJid
{
    // TODO : maybe use NSUIntegerMax
    // Ensure the back end supports NSUIntegerMax for both x86 and x64
    static const NSUInteger INFINITE_MESSAGE_COUNT = 10000;
    
    return [self buildRequestForRoom: roomJid
                               limit: INFINITE_MESSAGE_COUNT];
}

@end

// ???
//    [presense] - 070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)
//    [iq      ] - 070815_114612_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com

//    <iq
//      type='set'
//      id='4521814'                                           <!-- Random -->
//    >
//        <query
//            xmlns='urn:xmpp:mam:0'
//            queryid='7892897'>                               <!-- Random -->
//                <x xmlns='jabber:x:data'>
//                    <field var='FORM_TYPE'>
//                        <value>urn:xmpp:mam:0</value>
//                    </field>
//                    <field var='with'>
//                        <value>070815_114612_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com</value>
//                    </field>
//                    <field var='start'>
//                        <value>1970-01-01T00:00:00Z</value>  <!-- The service did not exist in 1970 -->
//                    </field>
//                </x>
//            <set xmlns='http://jabber.org/protocol/rsm'>
//                <max>1000</max>                              <!-- No Large chats expected -->
//            </set>
//        </query>
//    </iq>

