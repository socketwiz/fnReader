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

@property(unsafe_unretained, readonly) NSImage			*attachment;
@property(weak, readonly) NSString		*title;
@property(weak, readonly) NSDate			*published;
@property(weak, readonly) NSString		*author;
@property(weak, readonly) NSURL			*url;
@property(weak, readonly) NSURL			*baseUrl;
@property(weak, readonly) NSString		*content;
@property(weak, readonly) NSString		*txtContent;
@property(weak, readonly) NSString		*guid;
@property(weak, readonly) NSString		*rights;
@property(weak, readonly) NSDate			*created;
@property(weak, readonly) NSDate			*updated;
@property(weak, readonly) NSString		*summary;
@property(weak, readonly) NSString		*identifier;
@property(weak, readonly) NSDate			*received;
@property(weak, readonly) NSDate			*lastFetch;
@property(strong,readwrite) PSEntry	*entry;

- (NSImage *) read;
- (BOOL) readB;
- (void) setRead:(BOOL)aRead;

- (NSImage *) flagged;
- (void) setFlagged:(BOOL)aFlag;

- (NSString *) enclosureHTML: (PSEnclosure *)encl;
- (NSString *) enclosuresHTML;
@end
