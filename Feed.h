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

@property(readonly) NSImage			*icon;
@property(readonly)	NSImage			*logo;
@property(readonly) NSString		*title;
@property(readonly) NSImage			*unreadCountImg;
@property(readonly) int				unreadCount;
@property(readonly) NSURL			*url;
@property(readonly) NSURL			*altUrl;
@property(readonly) NSString		*subTitle;
@property(readonly) NSString		*rights;
@property(readonly) NSDate			*updated;
@property(readonly) NSString		*identifier;
@property(readonly) NSURL			*redirectedUrl;
@property(readonly) NSDate			*lastFetch;
@property(readonly) NSString		*error;
@property(retain,readwrite) PSFeed	*feed;

@property(retain,readwrite) NSMutableArray	*entries;
@property(readwrite) BOOL	bUpdating;

@end
