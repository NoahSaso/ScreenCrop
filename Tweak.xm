#import "Drag.h"

%hook SBScreenShotter

- (void)saveScreenshot:(BOOL)screenshot {
	DragWindow *wind = [[DragWindow alloc] initWithFrame:[[[UIApplication sharedApplication] keyWindow] frame]];
	[wind makeKeyAndVisible];
}

%end
