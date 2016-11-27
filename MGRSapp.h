#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>

@interface MGRSapp : UIApplication
{
	UIWindow *window;
	UIWebView *webView;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
@end
