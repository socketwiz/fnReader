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

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class IconViewController;
@class FileViewController;
@class ChildEditController;
@class PSClient,PSEntry;
@class Feed;
@class Error;
@class CTBadge;

@interface MyWindowController : NSWindowController
{
	IBOutlet NSTableView		*tblFeedsView;
	IBOutlet NSTableView		*tblEntriesView;
	IBOutlet NSView				*placeHolderView;
	IBOutlet NSSplitView		*splitView;
	IBOutlet WebView			*webView;
	IBOutlet NSArrayController	*aryEntriesController;
	IBOutlet NSArrayController	*aryFeedsController;

	IBOutlet NSButton			*addFolderButton;
	IBOutlet NSButton			*removeButton;
	IBOutlet NSTextField		*urlField;
	
	IBOutlet NSSearchField		*srchField;
	
	NSView						*currentView;
	ChildEditController			*childEditController;
	
	BOOL						buildingTableView;	// signifies we are building the table view at launch time
	
	NSArray						*dragNodesArray; // used to keep track of dragged nodes
	
	BOOL						retargetWebView;
	
    PSClient					*client;	// The PSClient is this application
	
	// list of feeds
	NSMutableArray				*feeds;
	Feed						*selectedFeed;
	
	Error						*_error;
	CTBadge						*_myBadge;
}

@property (strong) NSArray *dragNodesArray;
@property (strong, readwrite) NSMutableArray *feeds;

- (IBAction) addFeedAction:(id)sender;
- (IBAction) editFeedAction:(id)sender;
- (IBAction) removeFeedAction:(id)sender;
- (IBAction) flagFeedAction:(id)sender;
- (IBAction) markAllEntriesRead:(id)sender;

- (void) setColumnHeaderImage:(NSTableColumn *)imgColumn imageName:(NSString *)aImage;
- (void) formatTableColumns;

- (void) populateOutlineContents:(id)inObject;

- (void) tableViewSelectionDidChange:(NSNotification *)aNotification;

- (void) feedChanged: (NSNotification*)n;
- (void) feedRefreshing: (NSNotification*)n;
- (void) feedRefreshBrokenFeed: (NSNotification*)n;

- (void) refreshFavicons:(id)inObject;

- (void) updateUnreadCount;
- (BOOL)windowShouldClose:(id)sender;
@end
