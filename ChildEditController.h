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

@class MyWindowController;

@interface ChildEditController : NSWindowController
{
@private
	BOOL					cancelled;
	NSMutableDictionary		*savedFields;
	
	IBOutlet NSButton		*doneButton;
	IBOutlet NSButton		*cancelButton;
	IBOutlet NSTextView		*urlView;
}

- (NSMutableDictionary*)edit:(NSDictionary*)startingValues from:(MyWindowController*)sender;
- (BOOL)wasCancelled;

- (NSURL *) SmartURLFromString:(NSString *)str withSchemes:(NSArray *) allowedSchemes;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;
@end
