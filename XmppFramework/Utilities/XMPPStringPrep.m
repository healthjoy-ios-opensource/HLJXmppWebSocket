#import "XMPPStringPrep.h"


@implementation XMPPStringPrep

+ (NSString *)prepNode:(NSString *)node
{
	if(node == nil) return nil;
	
	// Each allowable portion of a JID MUST NOT be more than 1023 bytes in length.
	// We make the buffer just big enough to hold a null-terminated string of this length. 
	char buf[1024];
	
	strncpy(buf, [node UTF8String], sizeof(buf));
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
	if(stringprep_xmpp_nodeprep(buf, sizeof(buf)) != 0) return nil;
#pragma clang diagnostic pop
	
	return [NSString stringWithUTF8String:buf];
}

+ (NSString *)prepDomain:(NSString *)domain
{
	if(domain == nil) return nil;
	
	// Each allowable portion of a JID MUST NOT be more than 1023 bytes in length.
	// We make the buffer just big enough to hold a null-terminated string of this length. 
	char buf[1024];
	
	strncpy(buf, [domain UTF8String], sizeof(buf));
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
	if(stringprep_nameprep(buf, sizeof(buf)) != 0) return nil;
#pragma clang diagnostic pop
	
	return [NSString stringWithUTF8String:buf];
}

+ (NSString *)prepResource:(NSString *)resource
{
	if(resource == nil) return nil;
	
	// Each allowable portion of a JID MUST NOT be more than 1023 bytes in length.
	// We make the buffer just big enough to hold a null-terminated string of this length. 
	char buf[1024];
	
	strncpy(buf, [resource UTF8String], sizeof(buf));
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
	if(stringprep_xmpp_resourceprep(buf, sizeof(buf)) != 0) return nil;
#pragma clang diagnostic pop
	
	return [NSString stringWithUTF8String:buf];
}

+ (NSString *)prepPassword:(NSString *)password
{
	if(password == nil) return nil;
	
	// Each allowable portion of a JID MUST NOT be more than 1023 bytes in length.
	// We make the buffer just big enough to hold a null-terminated string of this length.
	char buf[1024];
	
	strncpy(buf, [password UTF8String], sizeof(buf));
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
	if(stringprep(buf, sizeof(buf), 0, stringprep_saslprep) != 0) return nil;
#pragma clang diagnostic pop    
	
	return [NSString stringWithUTF8String:buf];
}

@end
