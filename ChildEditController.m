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

#import "ChildEditController.h"

@implementation ChildEditController

// -------------------------------------------------------------------------------
//	init:
// -------------------------------------------------------------------------------
- (id)init
{
	self = [super init];
	return self;
}

// -------------------------------------------------------------------------------
//	windowNibName:
// -------------------------------------------------------------------------------
- (NSString*)windowNibName
{
	return @"ChildEdit";
}

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[super dealloc];
	[savedFields release];
}

// -------------------------------------------------------------------------------
//	edit:startingValues:from
// -------------------------------------------------------------------------------
- (NSMutableDictionary*)edit:(NSDictionary*)startingValues from:(MyWindowController*)sender
{
	NSWindow* window = [self window];

	cancelled = NO;

	if (startingValues != nil)
	{
		// we are editing current entry, use its values as the default
		savedFields = [startingValues retain];

		// clear first
		[[[urlView textStorage] mutableString] setString:@""];
		[urlView insertText:[startingValues objectForKey:@"url"]];
	}
	else
	{
		// we are adding a new entry,
		// make sure the form fields are empty due to the fact that this controller is recycled
		// each time the user opens the sheet -
		[[[urlView textStorage] mutableString] setString:@""];
	}
	
	[NSApp beginSheet: window 
	   modalForWindow: [sender window] 
		modalDelegate: nil 
	   didEndSelector: nil 
		  contextInfo: nil];
	[NSApp runModalForWindow: window];
	// sheet is up here...

	[NSApp endSheet:window];
	[window orderOut:self];

	return savedFields;
}

- (NSURL *) SmartURLFromString: (NSString *) str 
				   withSchemes: (NSArray *) allowedSchemes;
{
    NSURL *url = [NSURL URLWithString: str];
    if( url ) {
        NSString *scheme = [url scheme];
        if( scheme == nil ) {
            str = [@"http://" stringByAppendingString: str];
            url = [NSURL URLWithString: str];
            scheme = [url scheme];
        }
        if( !allowedSchemes || [allowedSchemes containsObject: scheme] )
            if( [[url host] length] && [url path]!= nil )
                return url;
    }
    return nil;
}

// -------------------------------------------------------------------------------
//	done:sender
// -------------------------------------------------------------------------------
- (IBAction)done:(id)sender
{

	if ([[[urlView textStorage] string] length] == 0)
	{
		// you must provide a URL
		NSBeep();
		return;
	}
	
	// save the values for later
	[savedFields release];

	NSString *trimmedUrl = [[[urlView textStorage] string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSURL* urlStr =  [self SmartURLFromString: trimmedUrl
								  withSchemes: [NSArray arrayWithObjects: @"http",@"https",@"file",@"feed",nil]];

	savedFields = [NSMutableDictionary dictionaryWithObjectsAndKeys: urlStr, @"url", nil];
	[savedFields retain];
	
	[NSApp stopModal];
}

// -------------------------------------------------------------------------------
//	cancel:sender
// -------------------------------------------------------------------------------
- (IBAction)cancel:(id)sender
{
	[NSApp stopModal];
	cancelled = YES;
}

// -------------------------------------------------------------------------------
//	wasCancelled:
// -------------------------------------------------------------------------------
- (BOOL)wasCancelled
{
	return cancelled;
}
@end