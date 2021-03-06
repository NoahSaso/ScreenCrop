#import "Drag.h"
#import "iOSVersion/iOSVersion.m"

extern "C" UIImage* _UICreateScreenUIImage();

//Define variables
CGPoint prevLoc;
CGRect holeRect;
DragView *dragView = nil;
UIColor *bgColor = [[UIColor clearColor] colorWithAlphaComponent:0.5f];
BOOL isOn = NO;
DragWindow* selfVar = nil;

@interface SpringBoard : UIApplication
-(void)cancelMenuButtonRequests;
-(void)clearMenuButtonTimer;
@end

@interface SBScreenFlash : NSObject
+(id)mySharedInstance;
+(id)sharedInstance;
+(id)mainScreenFlasher;
-(void)flash;
-(void)flashWhiteWithCompletion:(id)arg1;
@end

%hook SBScreenFlash
%group iOSOther
%new +(id)mySharedInstance {
    return [self sharedInstance];
}
%end
%group iOS8
%new +(id)mySharedInstance {
    return [self mainScreenFlasher];
}
%new -(void)flash {
    [self flashWhiteWithCompletion:nil];
}
%end
%end

%group All
%hook SpringBoard

-(void)_handleMenuButtonEvent {
    if(isOn){
        [self clearMenuButtonTimer];
        [self cancelMenuButtonRequests];

        //Clear whole screen
        holeRect = [[UIScreen mainScreen] bounds];
        holeRect.size.width += holeRect.size.width;
        holeRect.size.height += holeRect.size.height;
        [dragView setNeedsDisplay];

        //Wait for code above to take affect
        [self performSelector:@selector(takeIt) withObject:nil afterDelay:0.05];

    }else { %orig; }
}

%new -(void)takeIt {
    //Flash
    SBScreenFlash* screenFlash = [%c(SBScreenFlash) mySharedInstance];
    [screenFlash flash];

    //Take image
    UIImage *screenImage = _UICreateScreenUIImage();
    UIImageWriteToSavedPhotosAlbum(screenImage, nil, nil, nil);

    //Remove from screen
    [selfVar remove];
}

%end

@implementation DragWindow

-(id)initWithFrame:(CGRect)frame {
	if(self = [super initWithFrame:frame]){
        isOn = YES;
        selfVar = self;
		//Set rect to nothing
		holeRect = CGRectMake(0,0,0,0);
		prevLoc = CGPointMake(0,0);
		//Define the view to drag in
		dragView = [[DragView alloc] initWithFrame:frame];
		dragView.backgroundColor = bgColor;
		dragView.opaque = NO;
		//Add drag view to view
		[self addSubview:dragView];
	}
	return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//Get touch location and set origin point
	UITouch *touch = [touches anyObject];
	CGPoint tL = [touch locationInView:self];
	prevLoc = tL;

	//Set rect to nothing
	holeRect = CGRectMake(0,0,0,0);
	//Refresh dragView with rect (see very bottom)
	[dragView setNeedsDisplay];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	//Get touch location
	UITouch *touch = [touches anyObject];
	CGPoint tL = [touch locationInView:self];
	//Set rect to drag size
	holeRect = CGRectMake(prevLoc.x, prevLoc.y, tL.x-prevLoc.x, tL.y-prevLoc.y);
	//Refresh dragView with rect (see very bottom)
	[dragView setNeedsDisplay];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	//Get screenshot
    UIImage *screenImage = _UICreateScreenUIImage();

    //Scale dimensions because of retina
    CGRect cropRect = holeRect;
    cropRect.origin.x *= [UIScreen mainScreen].scale;
    cropRect.origin.y *= [UIScreen mainScreen].scale;
    cropRect.size.width *= [UIScreen mainScreen].scale;
    cropRect.size.height *= [UIScreen mainScreen].scale;

    //Crop screenshot to rect size
    CGImageRef imageRef = CGImageCreateWithImageInRect(screenImage.CGImage, cropRect);
    screenImage = [UIImage imageWithCGImage:imageRef]; 
    CGImageRelease(imageRef);
    NSLog(@"[ScreenCrop] Cropped screenshot");

    //Save screenshot
    UIImageWriteToSavedPhotosAlbum(screenImage, nil, nil, nil);
    NSLog(@"[ScreenCrop] Wrote screenshot");

    [self remove];
}

-(void)remove {
    //Remove window from screen
    dragView.backgroundColor = [UIColor clearColor];
    [dragView removeFromSuperview];
    [self resignKeyWindow];
    [self removeFromSuperview];
    isOn = NO;
    NSLog(@"[ScreenCrop] Kicked window from screen");
    [self release];
}

@end

@implementation DragView

-(void)drawRect:(CGRect)rect {
    // Start by filling the area with the color
    [bgColor setFill];
    UIRectFill(rect);

    // Assume that there's an ivar somewhere called holeRect of type CGRect
    // We could just fill holeRect, but it's more efficient to only fill the
    // area we're being asked to draw.
    CGRect holeRectIntersection = CGRectIntersection(holeRect, rect);

    //Fill the area with the rect with nothing
    [[UIColor clearColor] setFill];
    UIRectFill(holeRectIntersection);
}

@end
%end

%ctor {
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        %init(iOS8);
    }else {
        %init(iOSOther);
    }
    %init(All);
}
