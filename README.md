# HLJXmppWebSocket
Implements a limited sub-set of XMPP protocol (RFC3921). The transport is not limited to TCP and is designed with web sockets in mind.


## Supported stanza types :

1) Open 
```xml
<open 
    xmlns='urn:ietf:params:xml:ns:xmpp-framing' 
    to='xmpp-dev.healthjoy.com' 
    version='1.0'/>
```

2) Plain Auth

3) Presence (in order to enter the room) 
```xml
<presence 
    from='user+11952@xmpp-dev.healthjoy.com/6418684331436355063426182' 
    to='070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com/Qatest37 Qatest37 (id 11952)'
    xmlns='jabber:client'>
    
    <x xmlns='http://jabber.org/protocol/muc'/>

</presence>
```


4) Message 
 ```xml
 <message 
    to='070815_114612_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com' 
    type='groupchat' 
    xmlns='jabber:client'>
    <body>hello</body>
    <html xmlns='http://jabber.org/protocol/xhtml-im'>
         <body><p>hello</p></body>
    </html>
  </message>
 ```
 
5) Room history 
```xml
<iq type='set' id='3312369'>
    <query xmlns='urn:xmpp:mam:0' queryid='948960'>
        <x xmlns='jabber:x:data'>
            <field var='FORM_TYPE'>
                <value>urn:xmpp:mam:0</value>
            </field>
            
            <field var='with'>
                <value>070815_113113_qatest37_qatest37_general_question@conf.xmpp-dev.healthjoy.com</value>
            </field>
            
            <field var='start'>
                <value>1970-01-01T00:00:00Z</value>
            </field>
        </x>
        <set xmlns='http://jabber.org/protocol/rsm'>
            <max>1000</max>
        </set>
    </query>
</iq>
```


