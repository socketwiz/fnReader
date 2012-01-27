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
//  Feed.h
//  fnReader
//
//  Created by Ricky Nelson on 11/21/07.
//  Copyright 2007 Lark Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PSFeed;
@class Error;
@class CTBadge;

@interface Feed : NSObject {
	// model members
	NSString	*_title;
	NSImage		*_icon;
	NSImage		*_logo;
	CTBadge		*_unreadCountImg;
	PSFeed		*_feed;

	// list of feed entries
    NSMutableArray	*_entries;
	
	BOOL		_bUpdating;
	
	Error		*_error;
}

@property(unsafe_unretained, readonly) NSImage			*icon;
@property(unsafe_unretained, readonly)	NSImage			*logo;
@property(weak, readonly) NSString		*title;
@property(unsafe_unretained, readonly) NSImage			*unreadCountImg;
@property(readonly) int				unreadCount;
@property(weak, readonly) NSURL			*url;
@property(weak, readonly) NSURL			*altUrl;
@property(weak, readonly) NSString		*subTitle;
@property(weak, readonly) NSString		*rights;
@property(weak, readonly) NSDate			*updated;
@property(weak, readonly) NSString		*identifier;
@property(weak, readonly) NSURL			*redirectedUrl;
@property(weak, readonly) NSDate			*lastFetch;
@property(weak, readonly) NSString		*error;
@property(strong,readwrite) PSFeed	*feed;

@property(strong,readwrite) NSMutableArray	*entries;
@property(readwrite) BOOL	bUpdating;

@end
