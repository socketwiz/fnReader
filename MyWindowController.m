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

#import "MyWindowController.h"
#import "Error.h"
#import "CTBadge.h"
#import <PubSub/PubSub.h>


#import "ChildEditController.h"
#import "Feed.h"
#import "Entry.h"

#define CHILDEDIT_NAME			@"ChildEdit"	// nib name for the child edit window controller

#define HTTP_PREFIX				@"http://"

// default folder titles
#define SUBSCRIPTIONS_NAME		@"SUBSCRIPTIONS"

#define kMinOutlineViewSplit	120.0f

#define kNodesPBoardType		@"myNodesPBoardType"	// drag and drop pasteboard type


// -------------------------------------------------------------------------------
//	TreeAdditionObj
//
//	This object is used for passing data between the main and secondary thread
//	which populates the outline view.
// -------------------------------------------------------------------------------
@interface TreeAdditionObj : NSObject
{
	NSIndexPath *__weak indexPath;
	NSString	*__weak nodeURL;
	NSString	*__weak nodeName;
	BOOL		selectItsParent;
}

@property (readonly) NSIndexPath *indexPath;
@property (readonly) NSString *nodeURL;
@property (readonly) NSString *nodeName;
@property (readonly) BOOL selectItsParent;
@end

@implementation TreeAdditionObj
@synthesize indexPath, nodeURL, nodeName, selectItsParent;

// -------------------------------------------------------------------------------
- (id)initWithURL:(NSString *)url withName:(NSString *)name selectItsParent:(BOOL)select
{
	self = [super init];
	
	nodeName = name;
	nodeURL = url;
	selectItsParent = select;
	
	return self;
}
@end


@implementation MyWindowController

@synthesize dragNodesArray, feeds;

// -------------------------------------------------------------------------------
//	initWithWindow:window:
// -------------------------------------------------------------------------------
-(id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (self)
	{
		feeds = [[NSMutableArray alloc] init];
		_error = [[Error alloc] init];
	}
	
	//[window setDelegate:self];
	return self;
}
- (BOOL)windowShouldClose:(id)sender
{
	return FALSE;
}
- (void)performClose:(id)sender
{
	
	self.dragNodesArray = nil;
}

// -------------------------------------------------------------------------------
//	awakeFromNib:
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// load the child edit view controller for later use
	childEditController = [[ChildEditController alloc] initWithWindowNibName:CHILDEDIT_NAME];
	
	[[self window] setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
	[[self window] setContentBorderThickness:30 forEdge:NSMinYEdge];

    // Retain our PSClient, so that we can message it later
    client = [PSClient applicationClient];
    // Set ourselves as the PSClient delegate
    [client setDelegate: self];
/*
	// build our default tree on a separate thread,
	// some portions are from disk which could get expensive depending on the size of the dictionary file:
	[NSThread detachNewThreadSelector:	@selector(populateOutlineContents:)
										toTarget:self		// we are the target
										withObject:nil];
*/	
	[self populateOutlineContents:nil];
	
	[NSThread detachNewThreadSelector: @selector(refreshFavicons:)
							 toTarget: self
						   withObject: nil];
	
	// add images to our add/remove buttons
	NSImage *addImage = [NSImage imageNamed:NSImageNameAddTemplate];
	[addFolderButton setImage:addImage];
	NSImage *removeImage = [NSImage imageNamed:NSImageNameRemoveTemplate];
	[removeButton setImage:removeImage];
	
	// truncate to the middle if the url is too long to fit
	[[urlField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
	
	// make our outline view appear with gradient selection, and behave like the Finder, iTunes, etc.
	[tblFeedsView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	
	// drag and drop support
	[tblFeedsView registerForDraggedTypes:[NSArray arrayWithObjects:
											kNodesPBoardType,			// our internal drag type
											NSURLPboardType,			// single url from pasteboard
											NSFilenamesPboardType,		// from Safari or Finder
											NSFilesPromisePboardType,	// from Safari or Finder (multiple URLs)
											nil]];
	
	[webView setUIDelegate:self];		// be the webView's delegate to capture NSResponder calls
	[webView setPolicyDelegate:self];	// be the webView's delegate to capture clicks
	
    // Add ourself as an observer for a couple of notifications sent by PSFeed objects
    [[NSNotificationCenter defaultCenter] addObserver: self 
											 selector: @selector(feedRefreshing:)
                                                 name: PSFeedRefreshingNotification 
											   object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self 
											 selector: @selector(feedChanged:)
                                                 name: PSFeedEntriesChangedNotification 
											   object: nil];
	
	_myBadge = [[CTBadge alloc] init];
}

#pragma mark -
#pragma mark FEED ACTIONS:

// -------------------------------------------------------------------------------
//	addFeedAction:sender:
// -------------------------------------------------------------------------------
- (IBAction)addFeedAction:(id)sender
{
	// ask our edit sheet for information on the new child to be added
	NSMutableDictionary *newValues = [childEditController edit:nil from:self];
	
	if (![childEditController wasCancelled] && newValues)
	{
		NSURL *url   = [newValues objectForKey:@"url"];
		PSFeed *psFeed;

		@try {
			psFeed = [client addFeedWithURL:url];
		}
		@catch (NSException * e) {
			NSError *fError = [psFeed lastError];
			int iButton = 0;
			
			iButton = [_error errorAlert: e
						 informationText:[fError localizedDescription]
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
		
		if( [feeds containsObject: psFeed] )
		{
			return;
		}
		
		@try {
			NSArray *fdEntries = psFeed.entries;
			if ([fdEntries count] == 0)
			{
				[[NSNotificationCenter defaultCenter] addObserver: self 
														 selector: @selector(feedRefreshBrokenFeed:)
															 name: PSFeedRefreshingNotification 
														   object: psFeed];
			}
		}
		@catch (NSException * e) {
			NSError *fError = [psFeed lastError];
			int iButton = 0;
			
			iButton = [_error errorAlert: e
						 informationText:[fError localizedDescription]
							  buttonText:@"OK"
							  alertStyle:NSCriticalAlertStyle];
			
			//TODO: do something useful
			switch (iButton) {
				case NSAlertFirstButtonReturn:
					break;
				case NSAlertSecondButtonReturn:
					break;
				default:
					break;
			}
		}
		
		[aryFeedsController selectNext:sender];
	}
}

// -------------------------------------------------------------------------------
//	editFeedAction:sender:
// -------------------------------------------------------------------------------
- (IBAction)editFeedAction:(id)sender
{
	Feed *selectedFeedRow = [[aryFeedsController selectedObjects] objectAtIndex:0];
	
	if (selectedFeedRow)
	{
		PSFeed *selectedPSFeed  = selectedFeedRow.feed;
		NSDictionary* editInfo = [NSDictionary dictionaryWithObjectsAndKeys: [[selectedPSFeed URL] absoluteString], 
								  @"url", nil];

		// ask our sheet to edit the url value
		NSMutableDictionary *newValues = [childEditController edit:editInfo from:self];
		
		if (![childEditController wasCancelled] && newValues)
		{
			[aryFeedsController removeObject:selectedFeedRow];			
			[client removeFeed:selectedPSFeed];
			
			NSURL *url   = [newValues objectForKey:@"url"];
			PSFeed *psFeed;
			
			@try {
				psFeed = [client addFeedWithURL:url];
			}
			@catch (NSException * e) {
				NSError *fError = [psFeed lastError];
				int iButton = 0;
				
				iButton = [_error errorAlert: e
							 informationText:[fError localizedDescription]
								  buttonText:@"OK"
								  alertStyle:NSCriticalAlertStyle];
				//TODO: do something useful
				switch (iButton) {
					case NSAlertFirstButtonReturn:
						break;
					case NSAlertSecondButtonReturn:
						break;
					default:
						break;
				}
			}
		}
	}
}

- (IBAction)removeFeedAction:(id)sender
{
	selectedFeed = [[aryFeedsController selectedObjects] objectAtIndex:0];
	PSFeed *selectedPSFeed  = selectedFeed.feed;
	if (selectedPSFeed)
	{
		[aryFeedsController removeObject:selectedFeed];
		[client removeFeed:selectedPSFeed];
	}
}

- (IBAction)flagFeedAction:(id)sender
{
	Entry *selectedEntryRow = [[aryEntriesController selectedObjects] objectAtIndex:0];
	
	if (selectedEntryRow)
	{
		if ([selectedEntryRow flagged])
		{
			[selectedEntryRow setFlagged:NO];
		}
		else
		{
			[selectedEntryRow setFlagged:YES];
		}
	}
}

- (IBAction) markAllEntriesRead:(id)sender
{
	if ([tblFeedsView numberOfSelectedRows] > 0)
	{
		selectedFeed = [[aryFeedsController selectedObjects] objectAtIndex:0];
		
		// for some reason if there are 0 unread entries and you click the mark
		// all entries as unread button, it wipes out the entries list.  this 
		// hack where we check first to see if there are any unread entries
		// fixes that
		if ([selectedFeed unreadCount] > 0) {
			NSMutableArray *entriesArray = [selectedFeed mutableArrayValueForKey:@"entries"];
			//[entriesArray filterUsingPredicate:[NSPredicate predicateWithFormat:@"readB == YES"]];
			NSEnumerator *entriesEnumerator = [entriesArray objectEnumerator];
			id theEntry;
			
			while (theEntry = [entriesEnumerator nextObject]) {
				NSLog(@"Mark READ: %@\n", [theEntry title]);
				if (![theEntry isRead]) {
					[theEntry setRead:YES];
				}
			}
			
			[self updateUnreadCount];
		}
	}
	else
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"ERROR: must have a feed selected"
										 defaultButton: @"OK"
									   alternateButton: nil
										   otherButton: nil		 
							 informativeTextWithFormat:@"Please select a feed above before choosing to make all feeds as read"];
		
		[alert runModal];
	}
}


#pragma mark -
#pragma mark TABLE FORMATTING:

- (void) setColumnHeaderImage:(NSTableColumn *)imgColumn imageName:(NSString *)aImage
{
	NSTableHeaderCell * hcRead = [imgColumn headerCell];
	[hcRead setImage:[NSImage imageNamed:aImage]];
}

- (void) formatTableColumns
{	
	// feeds table
	NSTableColumn * tcLogo = [tblFeedsView tableColumnWithIdentifier:@"colLogo"];
	
	if	(tcLogo)
	{
		[tcLogo setMinWidth: 12.00];
		[tcLogo setWidth: 15.00];
	}
	
	NSTableColumn * tcTitle = [tblFeedsView tableColumnWithIdentifier:@"colTitle"];
	
	if	(tcTitle)
	{
		[tcTitle setMinWidth: 10.00];
		[tcTitle setWidth: 175.00];
	}
	
	NSTableColumn * tcUnread = [tblFeedsView tableColumnWithIdentifier:@"colUnread"];
	
	if	(tcUnread)
	{
		[tcUnread setMinWidth: 10.00];
		[tcUnread setWidth: 30.00];
	}
	
	
	// entries table
	NSTableColumn * tcRead = [tblEntriesView tableColumnWithIdentifier:@"colRead"];
	
	if	(tcRead)
	{
		[self setColumnHeaderImage:tcRead imageName:@"unread_header.tiff"];
		[tcRead setMinWidth: 10.00];
		[tcRead setWidth: 15.00];
	}
	
	NSTableColumn * tcFlag = [tblEntriesView tableColumnWithIdentifier:@"colFlag"];
	
	if	(tcFlag)
	{
		[self setColumnHeaderImage:tcFlag imageName:@"flagged_header.tiff"];
		[tcFlag setMinWidth: 10.00];
		[tcFlag setWidth: 15.00];
	}
	
	NSTableColumn * tcAttach = [tblEntriesView tableColumnWithIdentifier:@"colAttach"];
	
	if	(tcAttach)
	{
		[self setColumnHeaderImage:tcAttach imageName:@"attachment_header.tiff"];
		[tcAttach setMinWidth: 10.00];
		[tcAttach setWidth: 15.00];
	}
	
	NSTableColumn * tcSubject = [tblEntriesView tableColumnWithIdentifier:@"colSubject"];
	
	if	(tcSubject)
	{
		[tcSubject setMinWidth: 10.00];
		[tcSubject setWidth: 170.00];
	}
	
	NSTableColumn * tcDate = [tblEntriesView tableColumnWithIdentifier:@"colDate"];
	
	if	(tcDate)
	{
		[tcDate setMinWidth: 10.00];
		[tcDate setWidth: 100.00];
	}
	
	NSTableColumn * tcAuthor = [tblEntriesView tableColumnWithIdentifier:@"colAuthor"];
	
	if	(tcAuthor)
	{
		[tcAuthor setMinWidth: 10.00];
		[tcAuthor setWidth: 100.00];
	}
}

// -------------------------------------------------------------------------------
//	populateOutline:
//
//	Populate the tree controller from the PubSub feed list
// -------------------------------------------------------------------------------
- (void)populateOutline
{
    NSAssert(client,@"ERROR: No PubSub client set");
	
    NSArray *curFeeds = [client feeds];	
	NSMutableArray *newFeeds = [[NSMutableArray alloc] init];	
	
	for (PSFeed *curFeed in curFeeds) {
		@autoreleasepool {
			Feed *newFeed = [[Feed alloc] init];
			
			newFeed.feed = curFeed;

			[newFeeds addObject:newFeed];
		}
	}
	
	[self setFeeds:newFeeds];
	
}

// -------------------------------------------------------------------------------
//	populateOutlineContents:inObject
//
//	This method is being called on a separate thread to avoid blocking the UI
//	a startup time.
// -------------------------------------------------------------------------------
- (void)populateOutlineContents:(id)inObject
{
	@autoreleasepool {
	
		buildingTableView = YES;		// indicate to ourselves we are building the tables at startup

		[tblFeedsView setHidden:YES];	// hide the feed view - don't show it as we are building the contents

		[self formatTableColumns];
		[self populateOutline];			// add the PubSub outline content

		buildingTableView = NO;			// we're done building our tables

		
		[tblFeedsView setHidden:NO];	// we are done populating the outline view content, show it again	

		// preserve column sorting
		[tblEntriesView setAutosaveTableColumns: YES];
		[tblEntriesView setAutosaveName: @"tableEntries"];
		[tblEntriesView selectRowIndexes:0 byExtendingSelection:NO];
		
		// preserve window sizes
		[self setWindowFrameAutosaveName:@"fnReader"];
		
		[self updateUnreadCount];

	}
}

#pragma mark -
#pragma mark - WebView delegate

// -------------------------------------------------------------------------------
//	webView:makeFirstResponder
//
//	We want to keep the outline view in focus as the user clicks various URLs.
//
//	So this workaround applies to an unwanted side affect to some web pages that might have
//	JavaScript code thatt focus their text fields as we target the web view with a particular URL.
//
// -------------------------------------------------------------------------------
- (void)webView:(WebView *)sender makeFirstResponder:(NSResponder *)responder
{
	if (retargetWebView)
	{
		// we are targeting the webview ourselves as a result of the user clicking
		// a url in our tableView: don't do anything, but reset our target check flag
		//
		retargetWebView = NO;
	}
	else
	{
		// continue the responder chain
		[[self window] makeFirstResponder:sender];
	}
}

- (void)webView:(WebView *)sender 
decidePolicyForNavigationAction:(NSDictionary *)actionInformation 
		request:(NSURLRequest *)request 
		  frame:(WebFrame *)frame 
decisionListener:(id<WebPolicyDecisionListener>)listener
{
	if ([[[request URL] absoluteString] localizedCompare:@"about:blank"] == NSOrderedSame)
	{
		[listener use]; //ignore
	}
	else
	{
		NSLog(@"Launching URL: %@\n", [[request URL] absoluteString]);
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	}
}

#pragma mark -
#pragma mark TableView Delegate

// -------------------------------------------------------------------------------
//	removeSubview:
// -------------------------------------------------------------------------------
- (void)removeSubview
{
	// empty selection
	NSArray *subViews = [placeHolderView subviews];
	if ([subViews count] > 0)
	{
		[[subViews objectAtIndex:0] removeFromSuperview];
	}
	
	[placeHolderView displayIfNeeded];	// we want the removed views to disappear right away
}

// -------------------------------------------------------------------------------
//	changeItemView:
// ------------------------------------------------------------------------------
- (void)changeItemView
{
	if ([[aryEntriesController selectedObjects] count])
	{
		Entry *selectedEntryInTable = [[aryEntriesController selectedObjects] objectAtIndex:0];
		NSString *feedContentHtml   = selectedEntryInTable.content;
		
		// the url is a web-based url
		if (currentView != webView)
		{
			// change to web view
			[self removeSubview];
			currentView = nil;
			[placeHolderView addSubview:webView];
			currentView = webView;
		}
		
		// this will tell our WebUIDelegate not to retarget first responder since some web pages force
		// forus to their text fields - we want to keep our outline view in focus.
		retargetWebView = YES;	
		
		[webView setMainFrameURL:nil];		// reset the webview to an empty frame
		// re-target to the new HTML content
		[[webView mainFrame] loadHTMLString:feedContentHtml baseURL:nil];
		
		// mark feed as read
		selectedEntryInTable.read = YES;

		NSRect newBounds;
		newBounds.origin.x = 0;
		newBounds.origin.y = 0;
		newBounds.size.width = [[currentView superview] frame].size.width;
		newBounds.size.height = [[currentView superview] frame].size.height;
		[currentView setFrame:[[currentView superview] frame]];
		
		// make sure our added subview is placed and resizes correctly
		[currentView setFrameOrigin:NSMakePoint(0,0)];
		[currentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	}
	else
	{
		// there's no url associated with this node
		// so a container was selected - no view to display
		[self removeSubview];
		currentView = nil;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if (buildingTableView)	// we are currently building the feed view, don't change any view selections
		return;
	
	if ([aNotification object] == tblFeedsView)
	{
		if ([[aryFeedsController selectedObjects] count])
		{
			// reset search field when new feed is selected
			NSPredicate *clrSearch = [NSPredicate predicateWithFormat:nil];
			[aryEntriesController setFilterPredicate:clrSearch];
			
			selectedFeed = [[aryFeedsController selectedObjects] objectAtIndex:0];
		}
	}

	// ask the array controller for the current selection
	NSArray *selection = [aryEntriesController selectedObjects];
	if ([selection count] > 1)
	{
		// multiple selection - clear the right side view
		[self removeSubview];
		currentView = nil;
	}
	else
	{
		if ([selection count] == 1)
		{
			// single selection
			[self changeItemView];
		}
		else
		{
			// there is no current selection - no view to display
			[self removeSubview];
			currentView = nil;
		}
	}
	
	[self updateUnreadCount];
}

#pragma mark -
#pragma mark PubSub Feed Delegate

/**
 * if we change feeds, check to see if it exists in the model, if it does not
 * add it
 *
 */
- (void) feedChanged: (NSNotification*)n
{
    PSFeed *psFeed = [n object];
 	
	NSLog(@"CHANGING [%@]", psFeed);
	NSMutableArray *psFeeds = [[NSMutableArray alloc] init];
	Feed *curFeed = nil;
	
	// first grab an array of PSFeed objects so we can compare like things
	for (Feed *theFeed in feeds)
	{
		[psFeeds addObject:theFeed.feed];

		// while were at it, lets compare the Feed object identifiers
		// and grab the Feed object when we find a match so that we
		// can walk the Entries below for the Feed that was passed in to us
		if ([psFeed.identifier localizedCompare:[theFeed.feed identifier]] == NSOrderedSame)
		{
			curFeed = theFeed;
		}
	}
	
	// now find out if the PSFeed object we were passed exists in the model
	if (![psFeeds containsObject:psFeed])
	{
		NSLog(@"%@ FEED does not exist in model\n", psFeed);
		
		Feed *newFeed = [[Feed alloc] init];
		
		newFeed.feed = psFeed;
		
		// we need to grab the current list before setting "feeds" below
		NSMutableArray *appendedFeeds = [[NSMutableArray alloc] initWithArray:feeds];
		[appendedFeeds addObject:newFeed];
		[self setFeeds:appendedFeeds];
		
	}
	else
	{
		// feed exists so maybe some new entries came in
		if (curFeed != nil)
		{
			// we need to grab the current list before setting "entries" below
			NSMutableArray *appendedEntries = [curFeed entries];
			
			for (PSEntry *curEntry in [psFeed entries])
			{
				@autoreleasepool {
					BOOL bFoundEntry = NO;
					
					for (Entry *theEntry in appendedEntries)
					{
						if ([theEntry entry] == curEntry)
						{
							bFoundEntry = YES;
						}
					}

					if (bFoundEntry == NO)
					{
						Entry *newEntry = [[Entry alloc] init];
						NSLog(@"%@ ENTRY does not exist in Feed[%@]\n", curEntry, psFeed);
						
						newEntry.entry = curEntry;			
						[appendedEntries addObject:newEntry];
						curFeed.entries = appendedEntries;
					}

				}
			}
		}
		//curFeed.bUpdating = NO;
	}
	
}

// A feed has started or stopped refreshing.
- (void) feedRefreshing: (NSNotification*)n
{
    PSFeed *psFeed = [n object];
	Feed *curFeed = nil;

	for (Feed *theFeed in feeds)
	{
		if ([psFeed.identifier localizedCompare:[theFeed.feed identifier]] == NSOrderedSame)
		{
			curFeed = theFeed;
		}
	}

	if([psFeed isRefreshing] == NO) 
	{
		// finished refreshing
		NSLog(@"REFRESHING [%@] finished", psFeed);
		[self updateUnreadCount];
		
		curFeed.bUpdating = NO;
		// update icon to show were finshed updating
		[tblFeedsView reloadData];
	}
	else
	{
		NSLog(@"REFRESHING [%@] started", psFeed);
		curFeed.bUpdating = YES;
		// update icon to show were updating
		[tblFeedsView reloadData];
	}
}
- (void) feedRefreshBrokenFeed: (NSNotification*)n
{
    PSFeed *psFeed = [n object];

	// feed has completed refreshing
	if (psFeed.refreshing == 0)
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self 
														name: PSFeedRefreshingNotification 
													  object: nil];
			
        NSError *error = [psFeed lastError];

		if( [[error domain] isEqualToString: PSErrorDomain] && [error code] == PSNotAFeedError )
		{
            // The data at that URL is not a feed. Try to autodiscover a link to a feed:
            PSLink *bestLink = nil;
            
			for( PSLink *link in [psFeed links] ) 
			{
                switch( [link linkKind] ) 
				{
                    case PSLinkToAtom:
                        if( bestLink==nil || [bestLink linkKind]==PSLinkToRSS )
						{
                            bestLink = link;
						}
                        break;
					case PSLinkToRSS:
                        if( bestLink==nil )
						{
                            bestLink = link;
						}
                        break;
					default:
                        break;
                }
			}
            
            if( bestLink ) 
			{
                // Replace the current 'feed' with the real one:
                PSFeed *newFeed = [client addFeedWithURL: [bestLink URL]];
                
				if(newFeed && newFeed != psFeed)
				{
                    [client removeFeed: psFeed];
                }
            }
		}
	}
}


#pragma mark -
#pragma mark - TableView drag and drop

// ----------------------------------------------------------------------------------------
// draggingSourceOperationMaskForLocal <NSDraggingSource override>
// ----------------------------------------------------------------------------------------
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationMove;
}

// ----------------------------------------------------------------------------------------
// outlineView:writeItems:toPasteboard
// ----------------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:[NSArray arrayWithObjects:kNodesPBoardType, nil] owner:self];
	
	// keep track of this nodes for drag feedback in "validateDrop"
	self.dragNodesArray = items;
	
	return YES;
}

// -------------------------------------------------------------------------------
//	outlineView:validateDrop:proposedItem:proposedChildrenIndex:
//
//	This method is used by NSOutlineView to determine a valid drop target.
// -------------------------------------------------------------------------------
- (NSDragOperation)outlineView:(NSOutlineView *)ov
						validateDrop:(id <NSDraggingInfo>)info
						proposedItem:(id)item
						proposedChildIndex:(NSInteger)index
{
	NSDragOperation result = NSDragOperationNone;
	
	if (!item)
	{
		// no item to drop on
		result = NSDragOperationGeneric;
	}
	else
	{
		if (index == -1)
		{
			// don't allow dropping on a child
			result = NSDragOperationNone;
		}
		else
		{
			// drop location is a container
			result = NSDragOperationMove;
		}
	}
	
	return result;
}

// -------------------------------------------------------------------------------
//	handleWebURLDrops:pboard:withIndexPath:
//
//	The user is dragging URLs from Safari.
// -------------------------------------------------------------------------------
- (void)handleWebURLDrops:(NSPasteboard *)pboard withIndexPath:(NSIndexPath *)indexPath
{
	NSArray *pbArray = [pboard propertyListForType:@"WebURLsWithTitlesPboardType"];
	NSArray *urlArray = [pbArray objectAtIndex:0];
	NSArray *nameArray = [pbArray objectAtIndex:1];
	
	NSInteger i;
	for (i = ([urlArray count] - 1); i >= 0; i--)
	{
		NSLog(@"%@", [nameArray objectAtIndex:i]);
	}
}

// -------------------------------------------------------------------------------
//	handleInternalDrops:pboard:withIndexPath:
//
//	The user is doing an intra-app drag within the outline view.
// -------------------------------------------------------------------------------
- (void)handleInternalDrops:(NSPasteboard*)pboard withIndexPath:(NSIndexPath*)indexPath
{
	// user is doing an intra app drag within the outline view:
	//
	NSArray* newNodes = self.dragNodesArray;

	// move the items to their new place (we do this backwards, otherwise they will end up in reverse order)
	NSInteger i;
	for (i = ([newNodes count] - 1); i >=0; i--)
	{
//TODO: fix	
		//[tblFeedsView moveNode:[newNodes objectAtIndex:i] toIndexPath:indexPath];
		NSLog(@"Node[%@] indexPath[%@]", [newNodes objectAtIndex:i], indexPath);
	}
	
	// keep the moved nodes selected
	NSMutableArray* indexPathList = [NSMutableArray array];
	for (i = 0; i < [newNodes count]; i++)
	{
		[indexPathList addObject:[[newNodes objectAtIndex:i] indexPath]];
	}
//TODO: fix	
	//[treeController setSelectionIndexPaths: indexPathList];
	for (i = 0; i < [indexPathList count]; i++)
	{
		NSLog(@"indexPathList[%@]", [indexPathList objectAtIndex:i]);
	}
}

// -------------------------------------------------------------------------------
//	handleURLBasedDrops:pboard:withIndexPath:
//
//	Handle dropping a raw URL.
// -------------------------------------------------------------------------------
- (void)handleURLBasedDrops:(NSPasteboard*)pboard withIndexPath:(NSIndexPath*)indexPath
{
	NSURL *url = [NSURL URLFromPasteboard:pboard];
	if (url)
	{
		if ([url isFileURL])
		{
			// url is file-based, use it's display name
			NSString *name = [[NSFileManager defaultManager] displayNameAtPath:[url path]];
			NSLog(@"Name[%@]", name);
		}
		else
		{
			// url is non-file based (probably from Safari)
			//
			// the url might not end with a valid component name, use the best possible title from the URL
			if ([[[url path] pathComponents] count] == 1)
			{
				if ([[url absoluteString] hasPrefix:HTTP_PREFIX])
				{
					// use the url portion without the prefix
					NSRange prefixRange = [[url absoluteString] rangeOfString:HTTP_PREFIX];
					NSRange newRange = NSMakeRange(prefixRange.length, [[url absoluteString] length]- prefixRange.length - 1);
					NSLog(@"URL1[%@] loc[%lu] len[%lu]", 
						  [url absoluteString],
						  newRange.location,
						  newRange.length);
				}
				else
				{
					// prefix unknown, just use the url as its title
					NSLog(@"URL2[%@]", [url absoluteString]);
				}
			}
			else
			{
				// use the last portion of the URL as its title
				NSLog(@"URL3[%@]", [url absoluteString]);
			}
		}
	}
}

#pragma mark -
#pragma mark - Split View Delegate

// -------------------------------------------------------------------------------
//	splitView:constrainMinCoordinate:
//
//	What you really have to do to set the minimum size of both subviews to kMinOutlineViewSplit points.
// -------------------------------------------------------------------------------
- (float)splitView:(NSSplitView *)splitView constrainMinCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate + kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//	splitView:constrainMaxCoordinate:
// -------------------------------------------------------------------------------
- (float)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate - kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//	splitView:resizeSubviewsWithOldSize:
//
//	Keep the left split pane from resizing as the user moves the divider line.
// -------------------------------------------------------------------------------
- (void)splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect newFrame = [sender frame]; // get the new size of the whole splitView
	NSView *left = [[sender subviews] objectAtIndex:0];
	NSRect leftFrame = [left frame];
	NSView *right = [[sender subviews] objectAtIndex:1];
	NSRect rightFrame = [right frame];
 
	CGFloat dividerThickness = [sender dividerThickness];
	  
	leftFrame.size.height = newFrame.size.height;

	rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
	rightFrame.size.height = newFrame.size.height;
	rightFrame.origin.x = leftFrame.size.width + dividerThickness;

	[left setFrame:leftFrame];
	[right setFrame:rightFrame];
}

- (void)refreshFavicons:(id)inObject
{
	@autoreleasepool {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *favIconDirectory = [@"~/Library/Application Support/fnReader" stringByExpandingTildeInPath];
		
		BOOL bIsDir = NO;
		
		if ([fm fileExistsAtPath:favIconDirectory isDirectory:&bIsDir] == NO)
		{
			[fm createDirectoryAtPath:favIconDirectory 
		  withIntermediateDirectories:YES 
						   attributes:nil
								error:nil];
		}

		for (Feed *theFeed in [aryFeedsController arrangedObjects])
		{
			@try {
				NSString *strHost = [theFeed.url host];
				NSString *hostDirectory = [NSString stringWithFormat:@"%@/%@", 
										   favIconDirectory, strHost];
				
				if ([fm fileExistsAtPath:hostDirectory isDirectory:&bIsDir] == NO)
				{
					[fm createDirectoryAtPath:hostDirectory 
				  withIntermediateDirectories:YES
								   attributes:nil
										error:nil];
				}
				
				NSString *favIconFile = [NSString stringWithFormat:@"%@/%@",
										 hostDirectory, @"favicon.ico"];
				NSString *strUrl =  [NSString stringWithFormat:@"%@://%@/favicon.ico",
									 [theFeed.url scheme],
									 strHost];
				NSURL *favIconUrl = [NSURL URLWithString:strUrl];
				
				NSData *favIconData = [NSData dataWithContentsOfURL:favIconUrl];
				
				if (favIconData != nil)
				{
					[fm createFileAtPath: favIconFile 
								contents: favIconData
							  attributes: nil];
				}
			}
			@catch (NSException * e) {
				// most likely somebody nuked the feed before we could 
				// refresh the icon, so move along to the next feed
				NSLog(@"ERROR: [%@] %@", [e name], [e reason]);
				continue;
			}
		}
		
		/* 
		 * once the data has been downloaded refresh the table view
		 * so we can see the new favicons
		 *
		 */
		[tblFeedsView reloadData];
		
		NSLog(@"Icons have been refreshed");
	}
}

- (void) updateUnreadCount
{
	int iUnreadCount = 0;
	
	for (Feed *theFeed in [aryFeedsController arrangedObjects])
	{
		iUnreadCount += theFeed.unreadCount;
	}
	
	if (iUnreadCount)
	{		
		[_myBadge badgeApplicationDockIconWithValue:iUnreadCount insetX:3 y:0];
	}
	else
	{
		// remove badge
		NSImage *appIcon = [NSImage imageNamed:@"NSApplicationIcon"];
		[NSApp setApplicationIconImage:appIcon];
	}

	// if we get a click in the feed view outside of the range bad things can happen
	@try {
		Feed *currentFeed = [[aryFeedsController selectedObjects] objectAtIndex:0];
		PSFeed *currentPSFeed = [currentFeed feed];
		
		NSString *fmtUnread = [[NSString alloc] initWithFormat:@"%@ (%i entries, %i unread)", 
							   [currentFeed title], 
							   [[currentPSFeed entries] count],
							   iUnreadCount];
		
		[[self window] setTitle:fmtUnread];
	}
	@catch (NSException * e) {
		NSLog(@"ERROR: %@", [e reason]);
	}
}
@end
