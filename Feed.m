/*********************************************************************
 *                                                                    *
 *                         LARK SOFTWARE, LLC                         *
 *                                                                    *
 *                          PROPRIETARY DATA                          *
 *                                                                    *
 * THIS DOCUMENT CONTAINS TRADE SECRET DATA WHICH IS THE PROPERTY OF  *
 * LARK SOFTWARE. THIS DOCUMENT IS SUBMITTED TO RECIPIENT IN          *
 * CONFIDENCE. THIS DOCUMENT MAY NOT BE DISTRIBUTED TO ANYONE ELSE IN *
 * YOUR COMPANY, AND INFORMATION CONTAINED HEREIN MAY NOT BE USED,    *
 * COPIED OR DISCLOSED IN WHOLE OR IN PART EXCEPT AS PERMITTED BY     *
 * WRITTEN AGREEMENT SIGNED BY AN OFFICER OF LARK SOFTWARE.           *
 *                                                                    *
 * THIS MATERIAL IS ALSO COPYRIGHTED AS AN UNPUBLISHED WORK UNDER     *
 * TITLE 17 OF THE UNITED STATES CODE. UNAUTHORIZED USE, COPYING      *
 * OR OTHER REPRODUCTION IS PROHIBITED BY LAW.                        *
 *                                                                    *
 *               Copyright (C) 2007 LARK SOFTWARE, LLC.               *
 *                        ALL RIGHTS RESERVED.                        *
 *                                                                    *
 *********************************************************************/
//
//  Feed.m
//  fnReader
//
//  Created by Ricky Nelson on 11/21/07.
//  Copyright 2007 Lark Software, LLC. All rights reserved.
//

#import "Feed.h"
#import "Entry.h"
#import "Error.h"
#import "CTBadge.h"
#import <PubSub/PubSub.h>


@implementation Feed
@synthesize entries=_entries, bUpdating=_bUpdating;
@dynamic icon, logo, title, unreadCountImg, unreadCount, feed, altUrl, subTitle, rights;
@dynamic updated, identifier, redirectedUrl, lastFetch, error;

- (id) init
{
    if (self = [super init])
    {
		_icon  = [[NSImage alloc] init];
		_logo  = [[NSImage alloc] init];
		_title = [[NSString alloc] init];
		_unreadCountImg = [[CTBadge alloc] init];
		
		_error = [[Error alloc] init];
		
        _entries = [[NSMutableArray alloc] init];
		_bUpdating = NO;
    }
    return self;
}

- (void) dealloc
{
	[_icon release];
	[_logo release];
	[_title release];
	[_unreadCountImg release];
	
	[_error release];
	
    [_entries release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark ACCESSOR METHODS

/**
 * First check to see if the feed has a logo defined
 * if not attempt to grab the favicon.ico
 * it neither of those exist just put up a default feed icon
 */
- (NSImage *) icon
{
	if (_feed)
	{
		if (_bUpdating == YES)
		{
			return [NSImage imageNamed:@"NSActionTemplate"];
		}
		else
		{
			NSFileManager *fm = [NSFileManager defaultManager];
			NSString *favIconDirectory = [@"~/Library/Application Support/fnReader" stringByExpandingTildeInPath];
			NSString *strHost = [self.url host];
			NSString *hostDirectory = [NSString stringWithFormat:@"%@/%@", 
									   favIconDirectory, strHost];
			NSString *favIconFile = [NSString stringWithFormat:@"%@/%@",
									 hostDirectory, @"favicon.ico"];
			
			BOOL bIsDir = NO;

			if ([fm fileExistsAtPath:favIconFile isDirectory:&bIsDir] == YES)
			{
				[_icon autorelease];
				_icon = [[NSImage alloc] initByReferencingFile:favIconFile];
			}
			else
			{
				return [NSImage imageNamed:@"feed-icon"];
			}
		}

		return _icon;
	}
	
	return nil;
}
- (NSImage *) logo
{
	if (_feed)
	{
		[_logo autorelease];
		_logo = [[NSImage alloc] initWithContentsOfURL:_feed.logoURL];
		
		return _logo;
	}

	return nil;
}
- (NSString *) title
{
	[_title autorelease];
	if (_feed != nil)
	{		
		@try {
			if ([_feed.title length] > 0)
			{
				_title = [[NSString alloc] initWithString:_feed.title];
			}
			else
			{
				_title = [[NSString alloc] initWithString:[_feed.URL absoluteString]];
			}
		}
		@catch (NSException * e) {
			_title = [[NSString alloc] initWithString:@""];		
		}
	}
	else
	{
		_title = [[NSString alloc] initWithString:@""];		
	}

	return _title;
}
- (NSImage *) unreadCountImg
{
	if (_feed)
	{
		[_unreadCountImg release];
		_unreadCountImg = [[CTBadge alloc] init];
		return [_unreadCountImg smallBadgeForValue:_feed.unreadCount];
	}

	return nil;
}
- (int) unreadCount
{
	if (_feed)
	{
		return _feed.unreadCount;
	}
	
	return 0;
}
- (NSURL *) url
{
	if (_feed)
	{
		return _feed.URL;
	}
	
	return nil;
}
- (NSURL *) altUrl
{
	if (_feed)
	{
		return _feed.alternateURL;
	}
	
	return nil;
}
- (NSString *) subTitle
{
	if (_feed)
	{
		return _feed.subtitle;
	}
	
	return @"";
}
- (NSString *) rights
{
	if (_feed)
	{
		return _feed.rights;
	}
	
	return @"";
}
- (NSDate *) updated
{
	if (_feed)
	{
		return _feed.dateUpdated;
	}
	
	return NULL;
}
- (NSString *) identifier
{
	if (_feed)
	{
		return _feed.identifier;
	}
	
	return @"";
}
- (NSURL *) redirectedUrl
{
	if (_feed)
	{
		return _feed.redirectedURL;
	}
	
	return nil;
}
- (NSDate *) lastFetch
{
	if (_feed)
	{
		return _feed.localDateUpdated;
	}
	
	return NULL;
}
- (NSString *) error
{
	if (_feed)
	{			
	}
	
	return @"";
}

- (PSFeed *)feed
{
	return _feed;
}
- (void)setFeed:(PSFeed *)aFeed
{
	NSAssert(aFeed, @"ERROR: invalid Feed handle");
	
	if (_feed != aFeed)
    {
		NSLog(@"Initializing Feed: %@\n", aFeed.title);
		_feed = [aFeed retain];

		if ([_feed.entries count] > 0)
		{
			for (PSEntry *entry in _feed.entries) {
				NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
				Entry *newEntry = [[[Entry alloc] init] autorelease];

				@try {
					newEntry.entry = entry;			
					[self.entries addObject:newEntry];
				}
				@catch (NSException * e) {
					int iButton = 0;
					iButton = [_error errorAlert: e
								  informationText:@"Check the URL of the feed and ensure that is a valid feed"
									   buttonText:@"OK"
									   alertStyle:NSCriticalAlertStyle];
					
					switch (iButton) {
						case NSAlertFirstButtonReturn:
							break;
						case NSAlertSecondButtonReturn:
							break;
						default:
							break;
					}
				}
				@finally {					
					// cleanup entries, so we can loop through and add more
					[loopPool release];
				}
			}
		}
		else
		{
			Entry *newEntry = [[Entry alloc] init];				

			@try {
				[self.entries addObject:newEntry];
			}
			@catch (NSException * e) {
				int iButton = 0;
				
				iButton = [_error errorAlert: e
							 informationText:@""
								  buttonText:@"OK"
								  alertStyle:NSCriticalAlertStyle];
				
				switch (iButton) {
					case NSAlertFirstButtonReturn:
						break;
					case NSAlertSecondButtonReturn:
						break;
					default:
						break;
				}
			}
			@finally {					
				[newEntry release];
			}
		}
	}
}
@end
