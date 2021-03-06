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
//  Entry.m
//  fnReader
//
//  Created by Ricky Nelson on 11/21/07.
//  Copyright 2007 Lark Software, LLC. All rights reserved.
//

#import "Entry.h"
#import <PubSub/PubSub.h>


@implementation Entry
@synthesize entry=_entry;
@dynamic attachment,title,published,author,url,baseUrl,content,txtContent,guid;
@dynamic rights, created, updated, summary, identifier, received, lastFetch;

- (id) init
{
    if (self = [super init])
    {
		_read		= [[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForImageResource:@"read.tiff"]];
		_flagged	= [[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForImageResource:@"flag_red.tiff"]];
		_attachment	= [[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForImageResource:@"document_attachment.tiff"]];
    }
    return self;
}


#pragma mark -
#pragma mark ACCESSOR METHODS

- (NSImage *) read
{
	if (_entry)
	{
		if (_entry.read)
		{
			return nil;
		}
		else
		{
			return _read;
		}
	}

	return nil;
}
- (BOOL) readB
{
	if (_entry)
	{
		if (_entry.read)
		{
			return NO;
		}
		else
		{
			return YES;
		}
	}
	
	return NO;
}
- (void) setRead:(BOOL)aRead
{
	if (aRead)
	{
		_entry.read = YES;
	}
	else
	{
		_entry.read = NO;
	}
}

- (NSImage *) flagged
{
	if (_entry)
	{
		if (_entry.flagged)
		{
			return _flagged;
		}
		else
		{
			return nil;
		}
	}

	return nil;
}
- (void) setFlagged:(BOOL)aFlag
{
	if (_entry)
	{
		if (aFlag)
		{
			_entry.flagged = YES;
		}
		else
		{
			_entry.flagged = NO;
		}
	}
}

- (NSImage *)attachment
{
	if (_entry)
	{
		if ([_entry.enclosures count] > 0)
		{
			return _attachment;
		}
		else
		{
			return nil;
		}
	}

	return nil;
}

- (NSString *)title
{
	if (_entry)
	{
		return _entry.title;
	}

	return @"";
}
- (NSDate *)published
{
	if (_entry)
	{
		if (_entry.datePublished)
		{
			return _entry.datePublished;
		}
		else
		{
			// supposed to be guaranteed non-nil
			return _entry.dateForDisplay;
		}
	}

	return nil;
}
- (NSString *)author
{
	if (_entry)
	{
		return _entry.authorsForDisplay;
	}

	return @"";
}
- (NSURL *)url
{
	if (_entry)
	{
		return _entry.alternateURL;
	}

	return nil;
}
- (NSURL *)baseUrl
{
	if (_entry)
	{
		return _entry.baseURL;
	}
	
	return nil;
}
- (NSString *)content
{
	if (_entry)
	{
//		return _entry.content;
		
		// Get the title, if any. Entries don't have to have titles, but usually do.
		NSString *title = [_entry title];
		
		if( !title )
		{
			title = @"";
		}
		
		// Get the content, if any. Some entries only have a summary, some have nothing.
		NSString *content = [[_entry content] HTMLString];
		
		if( !content )
		{
			content = [[_entry summary] HTMLString];
		}
		if( !content )
		{
			content = @"";
		}
		
		// Get the alternateURL (sometimes also known as "permalink"). This is almost always
		// the url of the entry's web page.
		NSString *link = [[_entry alternateURL] absoluteString];
		
		if( !link ) link = @"";
		
		// Set the <base> value in the HTML, so that relative URLs in the content
		// will be interpreted correctly.
		NSString *base = [[_entry baseURL] absoluteString];
		
		if( !base )
		{
			base = link;
		}
		if( !base )
		{
			base = [[[_entry feed] alternateURL] absoluteString];
		}
		
		// Generate HTML for any enclosures:
		NSString *encls = [self enclosuresHTML];
		
		// There follows a very dumb (but easy!) HTML templating engine:
		// We plug the above values in to our template HTML, stored in our application's bundle.
		static NSString *sTemplate, *sNoLinkTemplate;
		
		// First, grab our templates out of our application's Resources directory
		if( !sTemplate )
		{
			NSString *path = [[NSBundle mainBundle] pathForResource: @"EntryTemplate" ofType: @"html"];
            NSError *error;
            sTemplate = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
			NSAssert(sTemplate,@"Can't load EntryTemplate.html");
			
			path = [[NSBundle mainBundle] pathForResource: @"EntryTemplate_NoLink" ofType: @"html"];
            sNoLinkTemplate = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
			NSAssert(sNoLinkTemplate,@"Can't load EntryTemplate.html");
		}
		
		NSString *template = [link length] ? sTemplate : sNoLinkTemplate;
		NSMutableString *html = [template mutableCopy];
		
		// Now, replace some constants that occur in the templates with our entry's data
		[html replaceOccurrencesOfString: @"{BASE}" withString: base
								 options: 0 range: NSMakeRange(0,[html length])];
		[html replaceOccurrencesOfString: @"{DATE}" withString: [[self published] description]
								 options: 0 range: NSMakeRange(0,[html length])];
		[html replaceOccurrencesOfString: @"{LINK}" withString: link
								 options: 0 range: NSMakeRange(0,[html length])];
		[html replaceOccurrencesOfString: @"{TITLE}" withString: title
								 options: 0 range: NSMakeRange(0,[html length])];
		[html replaceOccurrencesOfString: @"{CONTENT}" withString: content
								 options: 0 range: NSMakeRange(0,[html length])];
		[html replaceOccurrencesOfString: @"{ENCLOSURES}" withString: encls
								 options: 0 range: NSMakeRange(0,[html length])];
		return html;
	}
	else
	{
		return @"";
	}
}
- (NSString *)txtContent
{
	if (_entry)
	{
		return [_entry.content plainTextString];
	}
	
	return @"";
}
- (NSString *)guid
{
	if (_entry)
	{
		NSXMLElement *xml = _entry.XMLRepresentation;
		NSArray *guids = [xml elementsForName: @"id"];          // Atom
		
		if( [guids count] > 0 )
		{
			return [[guids objectAtIndex: 0] stringValue];		
		}

		guids = [xml elementsForName: @"guid"];                 // RSS
		
		if( [guids count] > 0 )
		{
			return [[guids objectAtIndex: 0] stringValue];
		}
	}
	
    return nil;
}
- (NSString *)rights
{
	if (_entry)
	{
		return _entry.rights;
	}
	
	return @"";
}
- (NSDate *)created
{
	if (_entry)
	{
		return _entry.dateCreated;
	}
	
	return nil;
}
- (NSDate *)updated
{
	if (_entry)
	{
		return _entry.dateUpdated;
	}
	
	return nil;
}
- (NSString *)summary
{
	if (_entry)
	{
		return [_entry.summary plainTextString];
	}
	
	return @"";
}
- (NSString *)identifier
{
	if (_entry)
	{
		return _entry.identifier;
	}
	
	return @"";
}
- (NSDate *)received
{
	if (_entry)
	{
		return _entry.localDateCreated;
	}
	
	return NULL;
}
- (NSDate *)lastFetch
{
	if (_entry)
	{
		return _entry.localDateUpdated;
	}
	
	return NULL;
}

- (NSString *) enclosureHTML: (PSEnclosure *)encl
{
    static NSString *sTemplate;
    if( ! sTemplate ) {
        NSString *path = [[NSBundle mainBundle] pathForResource: @"EnclosureTemplate" ofType: @"html"];
        NSError *error;
        sTemplate = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        NSAssert(sTemplate,@"Can't load EnclosureTemplate.html");
    }
	
    NSString *urlStr = [[encl URL] absoluteString];
    NSString *name = [[[encl URL] path] lastPathComponent];
    NSString *type = [encl MIMEType];
    if( ! type )
        type = @"";
    long long length = [encl length];
    NSString *lengthStr = length ?[NSString stringWithFormat: @"(%.0f KB)", length/1024.0]
	: @"";
    
    NSMutableString *html = [sTemplate mutableCopy];
    [html replaceOccurrencesOfString: @"{URL}" withString: urlStr
							 options: 0 range: NSMakeRange(0,[html length])];
    [html replaceOccurrencesOfString: @"{NAME}" withString: name
							 options: 0 range: NSMakeRange(0,[html length])];
    [html replaceOccurrencesOfString: @"{TYPE}" withString: type
							 options: 0 range: NSMakeRange(0,[html length])];
    [html replaceOccurrencesOfString: @"{LENGTH}" withString: lengthStr
							 options: 0 range: NSMakeRange(0,[html length])];
    return html;
}

- (NSString *) enclosuresHTML
{
    NSMutableString *html = [NSMutableString string];
    for( PSEnclosure *encl in [_entry enclosures] )
        [html appendString: [self enclosureHTML: encl]];
    return html;
}
@end
