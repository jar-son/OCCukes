// OCCukes OCCucumberRuntime.m
//
// Copyright © 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the “Software”), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "OCCucumberRuntime.h"

@interface OCCucumberRuntime()

// The wire socket accepts connections on a prescribed host and port, typically
// local host, port 54321. Wire pairs represent a set of Core Foundation stream
// pairs for individual connections to remote wire clients, typically Ruby
// interpreters running Cucumber. Wire pairs appear when the wire socket accepts
// a new connection and disappear when the remote Cucumber client closes the
// connection.
@property(strong, NS_NONATOMIC_IOSONLY) CFSocket *wireSocket;
@property(strong, NS_NONATOMIC_IOSONLY) NSMutableSet *wirePairs;

@end

@implementation OCCucumberRuntime

@synthesize wireSocket = _wireSocket;
@synthesize wirePairs = _wirePairs;

- (void)setUp
{
	CFSocket *socket = [[CFSocket alloc] initForTCPv6];
	[socket setDelegate:self];
	[socket setReuseAddressOption:YES];
	[socket setAddress:CFSocketAddressDataFromAnyIPv6WithPort(54321) error:NULL];
	[socket addToCurrentRunLoopForCommonModes];
	[self setWireSocket:socket];
	[self setWirePairs:[NSMutableSet set]];
}

- (void)tearDown
{
	// Removing all connections automatically closes the connections because the
	// request-response stream pair closes on deallocation. Therefore, no need
	// to explicitly close every pair, as follows. Releasing the socket shuts
	// down the socket. Releasing the pair set releases and shuts down all the
	// wire connections.
	//
	//	for (CFStreamPair *wirePair in [self wirePairs])
	//	{
	//		[wirePair close];
	//	}
	//
	[self setWireSocket:nil];
	[self setWirePairs:nil];
}

- (void)run
{
	do
	{
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10.0]];
	}
	while ([[self wirePairs] count]);
}

- (void)socket:(CFSocket *)socket acceptStreamPair:(CFStreamPair *)streamPair
{
	// Accepts new connections. Attaches a stream-pair to each incoming
	// connection. Retains, delegates and opens the new wire pair.
	[[self wirePairs] addObject:streamPair];
	[streamPair setDelegate:self];
	[streamPair open];
}

- (void)streamPair:(CFStreamPair *)streamPair hasBytesAvailable:(NSUInteger)bytesAvailable
{
	NSString *line = [streamPair receiveLineUsingEncoding:NSUTF8StringEncoding];
	if (line)
	{
		
	}
}

- (void)streamPair:(CFStreamPair *)streamPair handleRequestEvent:(NSStreamEvent)eventCode
{
	switch (eventCode)
	{
		case NSStreamEventEndEncountered:
			[[self wirePairs] removeObject:streamPair];
	}
}

@end