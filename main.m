#import <math.h>
#import <string.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIView.h>
#import <UIKit/UIWebView.h>
//#import <GraphicsServices/GraphicsServices.h>
#import "MGRSapp.h"
#include "mgrslib/mgrs.h"

/* Copyright (C) 2009-2016 Aero Teknic Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of version 2 of the GNU General Public License as
   published by the Free Software Foundation.
*/

int
main(int argc, char **argv)
{

	NSAutoreleasePool *autoreleasePool = [
										  [ NSAutoreleasePool alloc ] init
										  ];
	int returnCode = UIApplicationMain(argc, argv, @"MGRSapp", @"MGRSapp");
	[ autoreleasePool release ];
	return returnCode;
}

@implementation MGRSapp

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	//[[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    UIViewController *vc = [[UIViewController alloc] init];
	
	window = [ [ UIWindow alloc ] initWithContentRect:
			  [[UIScreen mainScreen] applicationFrame]
			  ];
    /*/http://stackoverflow.com/questions/7520971/applications-are-expected-to-have-a-root-view-controller-at-the-end-of-applicati
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for(UIWindow *window in windows) {
        if(window.rootViewController == nil){
            UIViewController* vc = [[UIViewController alloc]initWithNibName:nil bundle:nil];
            window.rootViewController = vc;
        }
    }*/
	
	
	CGRect rect = [[UIScreen mainScreen] applicationFrame];
	rect.origin.x = rect.origin.y = 0.0f;

	webView = [ [ UIWebView alloc] initWithFrame: rect ];
	webView.delegate = self;
	NSString *path = [ [ NSBundle mainBundle ]
		 pathForResource:@"mgrs.embedded.html" ofType:nil
	];
	NSURL *fileURL = [ [ NSURL alloc ] initFileURLWithPath:path ];
	NSURLRequest *req = [ NSURLRequest requestWithURL:fileURL ];
	[ webView loadRequest:req ];
	//[ window setContentView: webView ];
        [vc.view addSubview:webView];
	[ window orderFront: self ];
	[ window makeKey: self ];
    
    window.rootViewController = vc;

}

- (BOOL)webView:(UIWebView *)webView2
	shouldStartLoadWithRequest:(NSURLRequest *)request
	navigationType:(UIWebViewNavigationType)navigationType
{
	NSString *url = [ [ request URL ] absoluteString ];
	if ([ url hasPrefix:@"mgrs-convert:" ]) {
    
		NSArray *components = [ url componentsSeparatedByString:@":" ];
		NSString *coordinates = [ components objectAtIndex:1 ];
    
		[ self convert:[ coordinates UTF8String ] ];
		return NO;
	}
	return YES;
}

- (void)conversion_error:(const char *)message {
	[ webView stringByEvaluatingJavaScriptFromString:[
		NSString stringWithFormat:@"conversion_error(\"%s\")", message
	] ];
}

- (void)convert:(const char *)input {
	double lat, lon;

	if (
		(strlen(input) < 7) ||
		(!((input[0] >= '0') && (input[0] <= '9'))) ||
		(!((input[1] >= '0') && (input[1] <= '9'))) ||
		(!((input[2] >= 'C') && (input[2] <= 'X'))) ||
		(!((input[3] >= 'A') && (input[3] <= 'Z'))) ||
		(!((input[4] >= 'A') && (input[4] <= 'Z'))) ||
		(input[2] == 'I') || (input[2] == 'O') ||
		(input[3] == 'I') || (input[3] == 'O') ||
		(input[4] == 'I') || (input[4] == 'O') ||
		((strlen(input) & 1) == 0) ||
		(strlen(input) > 15)
	) {
		[ self conversion_error:"Syntax error in MGRS" ];
		return;
	}
	
	long result = Convert_MGRS_To_Geodetic(input, &lat, &lon);
	
	if (result) {
		if (result & MGRS_LAT_ERROR) {
			[ self conversion_error: "Latitude outside of valid range" ];
		} else if (result & MGRS_LON_ERROR) {
			[ self conversion_error: "Longitude outside of valid range" ];
		} else if (result & MGRS_STRING_ERROR) {
			[ self conversion_error: "MGRS string format error" ];
		} else if (result & MGRS_PRECISION_ERROR) {
			[ self conversion_error: "MGRS precision error" ];
		} else if (result & MGRS_A_ERROR) {
			[ self conversion_error: "Semi-major axis <= 0" ];
		} else if (result & MGRS_INV_F_ERROR) {
			[ self conversion_error: "Inverse flattening outside range" ];
		} else if (result & MGRS_EASTING_ERROR) {
			[ self conversion_error: "Easting outside range" ];
		} else if (result & MGRS_NORTHING_ERROR) {
			[ self conversion_error: "Northing outside range" ];
		} else if (result & MGRS_ZONE_ERROR) {
			[ self conversion_error: "Zone outside range" ];
		} else if (result & MGRS_HEMISPHERE_ERROR) {
			[ self conversion_error: "Invalid hemisphere" ];
		} else {
			[ self conversion_error: "Unknown MGRS conversion error" ];
		}
	} else {
		lat = lat / M_PI * 180.0;
		lon = lon / M_PI * 180.0;
		[ webView stringByEvaluatingJavaScriptFromString:[
			NSString stringWithFormat:@"conversion_success(%.10f,%.10f)",
			lat, lon
		] ];
	}
}

@end
