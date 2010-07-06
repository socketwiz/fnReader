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
//
//  Entry.h
//  fnReader
//
//  Created by Ricky Nelson on 11/21/07.
//  Copyright 2007 Lark Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PSEntry, PSContent, PSEnclosure;

@interface Entry: NSObject {
	// model members
	NSImage *_read;
	NSImage *_flagged;
	NSImage *_attachment;
	PSEntry	*_entry;
}

@property(readonly) NSImage			*attachment;
@property(readonly) NSString		*title;
@property(readonly) NSDate			*published;
@property(readonly) NSString		*author;
@property(readonly) NSURL			*url;
@property(readonly) NSURL			*baseUrl;
@property(readonly) NSString		*content;
@property(readonly) NSString		*txtContent;
@property(readonly) NSString		*guid;
@property(readonly) NSString		*rights;
@property(readonly) NSDate			*created;
@property(readonly) NSDate			*updated;
@property(readonly) NSString		*summary;
@property(readonly) NSString		*identifier;
@property(readonly) NSDate			*received;
@property(readonly) NSDate			*lastFetch;
@property(retain,readwrite) PSEntry	*entry;

- (NSImage *) read;
- (BOOL) readB;
- (void) setRead:(BOOL)aRead;

- (NSImage *) flagged;
- (void) setFlagged:(BOOL)aFlag;

- (NSString *) enclosureHTML: (PSEnclosure *)encl;
- (NSString *) enclosuresHTML;
@end
