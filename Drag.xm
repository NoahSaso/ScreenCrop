#import "Drag.h"

extern "C" UIImage* _UICreateScreenUIImage();

//Define variables
CGPoint prevLoc;
CGRect holeRect;
DragView *dragView;
UIColor *bgColor = [[UIColor clearColor] colorWithAlphaComponent:0.5f];

@implementation DragWindow

- (id)initWithFrame:(CGRect)frame {
	if(self = [super initWithFrame:frame]){
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	//Get touch location and set origin point
	UITouch *touch = [touches anyObject];
	CGPoint tL = [touch locationInView:self];
	prevLoc = tL;

	//Set rect to nothing
	holeRect = CGRectMake(0,0,0,0);
	//Refresh dragView with rect (see very bottom)
	[dragView setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	//Get touch location
	UITouch *touch = [touches anyObject];
	CGPoint tL = [touch locationInView:self];
	//Set rect to drag size
	holeRect = CGRectMake(prevLoc.x, prevLoc.y, tL.x-prevLoc.x, tL.y-prevLoc.y);
	//Refresh dragView with rect (see very bottom)
	[dragView setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	//Get screenshot
    UIImage *screenImage = _UICreateScreenUIImage();

    //Double dimensions because of retina
    CGRect cropRect = holeRect;
    cropRect.origin.x += cropRect.origin.x;
    cropRect.origin.y += cropRect.origin.y;
    cropRect.size.width += cropRect.size.width;
    cropRect.size.height += cropRect.size.height;

    //Crop screenshot to rect size
    CGImageRef imageRef = CGImageCreateWithImageInRect(screenImage.CGImage, cropRect);
    screenImage = [UIImage imageWithCGImage:imageRef]; 
    CGImageRelease(imageRef);
    NSLog(@"[ScreenCrop] Cropped screenshot");

    //Remove gray
    self.backgroundColor = [UIColor clearColor];

    //Save screenshot
    UIImageWriteToSavedPhotosAlbum(screenImage, nil, nil, nil);
    NSLog(@"[ScreenCrop] Wrote screenshot");

    //Remove window from screen
    [dragView removeFromSuperview];
    [self resignKeyWindow];
    [self removeFromSuperview];
    [self release];
    NSLog(@"[ScreenCrop] Kicked window from screen");
}

@end

@implementation DragView

- (void)drawRect:(CGRect)rect {
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