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
{
    NSString* messageFormat =
    @"    <iq                                                       \n"
    @"      type='set'                                              \n"
    @"      id='%@'                                                 \n" //<!-- Random -->
    @"    >                                                         \n"
    @"        <query                                                \n"
    @"            xmlns='urn:xmpp:mam:0'                            \n"
    @"            queryid='%@'>                                     \n" //<!-- Random -->
    @"                <x xmlns='jabber:x:data' type='submit'>       \n"
    @"                    <field var='FORM_TYPE'>                   \n"
    @"                        <value>urn:xmpp:mam:0</value>         \n"
    @"                    </field>                                  \n"
    @"                    <field var='withroom'>                    \n" // [dev, "withroom"], [prod : "with"]
    @"                        <value>%@</value>                     \n" // roomJid
    @"                    </field>                                  \n"
    @"                    <field var='start'>                       \n"
    @"                        <value>1970-01-01T00:00:00Z</value>   \n" // <!-- The service did not exist back in 1970 -->
    @"                    </field>                                  \n"
    @"                </x>                                          \n"
    @"            <set xmlns='http://jabber.org/protocol/rsm'>      \n"
    @"                <max>10000</max>                              \n" // No way to request everything. Using a large constant
    @"            </set>                                            \n"
    @"        </query>                                              \n"
    @"    </iq>";
    
    NSString* randomIdForIq    = [self->_randomizer getRandomIdForStanza];
    NSString* randomIdForQuery = [self->_randomizer getRandomIdForStanza];
    
    NSString* request = [NSString stringWithFormat: messageFormat, randomIdForIq, randomIdForQuery, roomJid];
    
    HJChatHistoryRequest* result = [HJChatHistoryRequest new];
    {
        result.dataToSend = request         ;
        result.idForIq    = randomIdForIq   ;
        result.idForQuery = randomIdForQuery;
    }
    
    return result;
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

