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
//  Error.m
//  fnReader
//
//  Created by Ricky Nelson on 12/2/07.
//  Copyright 2007 Lark Software, LLC. All rights reserved.
//

#import "Error.h"


@implementation Error
- (id) init
{
	self = [super init];
	if (self != nil) {
		_alert = [[NSAlert alloc] init];
	}
	return self;
}

- (int) errorAlert:(NSException *) e
   informationText:(NSString *) info
		buttonText:(NSString *) button
		alertStyle:(int) style
{
    [self printStackTrace:e];
	
	[_alert addButtonWithTitle:button];
	[_alert addButtonWithTitle:@"Cancel"];
	[_alert setMessageText:[[e userInfo] objectForKey:NSLocalizedDescriptionKey]];
	[_alert setInformativeText:info];
	
	switch (style) {
		case NSWarningAlertStyle:
			[_alert setAlertStyle:NSWarningAlertStyle];
			break;
		case NSInformationalAlertStyle:
			[_alert setAlertStyle:NSInformationalAlertStyle];
			break;
		case NSCriticalAlertStyle:
			[_alert setAlertStyle:NSCriticalAlertStyle];
			break;
		default:
			break;
	}

	NSInteger modalReturn = [_alert runModal];
	
	switch (modalReturn) {
		case NSAlertFirstButtonReturn:
			return NSAlertFirstButtonReturn;
			break;
		case NSAlertSecondButtonReturn:
			return NSAlertSecondButtonReturn;
			break;
		case NSAlertThirdButtonReturn:
			return NSAlertThirdButtonReturn;
			break;
		default:
			return -1;
			break;
	}
	
//	[alert release];
}

- (void)printStackTrace:(NSException *)e
{
    NSString *stack = [[e userInfo] objectForKey:NSStackTraceKey];
    if (stack) {
        NSTask *ls = [[NSTask alloc] init];
        NSString *pid = [[NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]] stringValue];
        NSMutableArray *args = [NSMutableArray arrayWithCapacity:20];
		
        [args addObject:@"-p"];
        [args addObject:pid];
        [args addObjectsFromArray:[stack componentsSeparatedByString:@"  "]];
        // Note: function addresses are separated by double spaces, not a single space.
		
        [ls setLaunchPath:@"/usr/bin/atos"];
        [ls setArguments:args];
        [ls launch];
		
    } else {
        NSLog(@"No stack trace available.");
    }
}
@end
