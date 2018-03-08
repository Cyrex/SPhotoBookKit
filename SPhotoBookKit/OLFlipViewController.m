//
//  MPFlipViewController.m
//  MPFlipViewController
//
//  Created by Mark Pospesel on 6/4/12.
//  Copyright (c) 2012 Mark Pospesel. All rights reserved.
//

#import "OLFlipViewController.h"
#import	"OLFlipTransition.h"

#define MARGIN	44
#define SWIPE_THRESHOLD	125.0f
#define SWIPE_ESCAPE_VELOCITY 650.0f

// Notifications
NSString *OLFlipViewControllerDidFinishAnimatingNotification = @"com.markpospesel.OLFlipViewControllerDidFinishAnimatingNotification";

@interface OLFlipViewController ()

@property (nonatomic, assign) OLFlipViewControllerOrientation orientation;
@property (nonatomic, strong) UIViewController *childViewController;
@property (nonatomic, strong) UIViewController *sourceController;
@property (nonatomic, strong) UIViewController *destinationController;
@property (nonatomic, assign) NSArray *gestureRecognizers;
@property (nonatomic, assign) BOOL gesturesAdded;
@property (nonatomic, readonly) BOOL isAnimating;
@property (nonatomic, assign, getter = isGestureDriven) BOOL gestureDriven;
@property (nonatomic, assign, getter = isPanning) BOOL panning;
@property (nonatomic, assign, getter = isRubberbanding) BOOL rubberbanding;
@property (nonatomic, strong) OLFlipTransition *flipTransition;
@property (assign, nonatomic) CGPoint panStart;
@property (assign, nonatomic) CGPoint lastPanPosition;
@property (assign, nonatomic) BOOL animationDidStartAsPan;
@property (nonatomic, assign) OLFlipViewControllerDirection direction;

@end

@implementation OLFlipViewController

@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;

@synthesize orientation = _orientation;
@synthesize childViewController = _childViewController;
@synthesize gestureRecognizers = _gestureRecognizers;
@synthesize gesturesAdded = _gesturesAdded;
@synthesize gestureDriven = _gestureDriven;
@synthesize panning = _panning;
@synthesize rubberbanding = _rubberbanding;
@synthesize flipTransition = _flipTransition;
@synthesize panStart = _panStart;
@synthesize lastPanPosition = _lastPanPosition;
@synthesize animationDidStartAsPan = _animationDidStartAsPan;
@synthesize direction = _direction;
@synthesize sourceController = _sourceController;
@synthesize destinationController = _destinationController;

- (id)initWithOrientation:(OLFlipViewControllerOrientation)orientation
{
    self = [super init];
    if (self) {
        // Custom initialization
		_orientation = orientation;
		_direction = OLFlipViewControllerDirectionForward;
		_gesturesAdded = NO;
		_panning = NO;
		_gestureDriven = NO;
		_rubberbanding = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

	[self addGestures];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

#pragma mark - rotation callbacks

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return ![self isAnimating];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if ([[self delegate] respondsToSelector:@selector(flipViewController:orientationForInterfaceOrientation:)])
		[self setOrientation:[[self delegate] flipViewController:self orientationForInterfaceOrientation:toInterfaceOrientation]];
	
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - Properties

- (UIViewController *)viewController
{
	return [self childViewController];
}

- (BOOL)isAnimating
{
	return [self flipTransition] != nil;
}

- (BOOL)isFlipFrontPage
{
	return [[self flipTransition] stage] == OLFlipAnimationStage1;
}

- (void)setPanning:(BOOL)panning
{
	if (_panning != panning)
	{
		_panning = panning;
		if (panning)
		{
			[self setAnimationDidStartAsPan:YES];
		}
	}
}

#pragma mark - private instance methods

- (void)addGestures
{
	if ([self gesturesAdded])
		return;
	
	// Add our swipe gestures
	BOOL isHorizontal = ([self orientation] == OLFlipViewControllerOrientationHorizontal);
	UISwipeGestureRecognizer *left = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeNext:)];
	left.direction = isHorizontal? UISwipeGestureRecognizerDirectionLeft : UISwipeGestureRecognizerDirectionUp;
	left.delegate = self;
	[self.view addGestureRecognizer:left];
	
	UISwipeGestureRecognizer *right = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipePrev:)];
	right.direction = isHorizontal? UISwipeGestureRecognizerDirectionRight : UISwipeGestureRecognizerDirectionDown;
	right.delegate = self;
	[self.view addGestureRecognizer:right];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	tap.delegate = self;
	[self.view addGestureRecognizer:tap];
	
	UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	pan.delegate = self;
	[self.view addGestureRecognizer:pan];
	
	self.gestureRecognizers = [NSArray arrayWithObjects:left, right, tap, pan, nil];

	[self setGesturesAdded:YES];
}

#pragma mark - public Instance methods

- (void)setViewController:(UIViewController *)viewController direction:(OLFlipViewControllerDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
	UIViewController *previousController = [self viewController];
	
	BOOL isForward = (direction == OLFlipViewControllerDirectionForward);
	[[viewController view] setFrame:[self.view bounds]];
	[self addChildViewController:viewController]; // this calls [viewController willMoveToParentViewController:self] for us
	[self setChildViewController:viewController];
	[previousController willMoveToParentViewController:nil];
	
	if (animated && previousController)
	{
		[self startFlipToViewController:viewController 
					 fromViewController:previousController 
						  withDirection:(isForward? OLFlipStyleDefault : OLFlipStyleDirectionBackward)];
		
		[self.flipTransition perform:^(BOOL finished) {
			[self endFlipAnimation:finished transitionCompleted:YES completion:completion];
		}];
	}
	else 
	{
		[[self view] addSubview:[viewController view]];
		[[previousController view] removeFromSuperview];
		[viewController didMoveToParentViewController:self];
		if (completion)
			completion(YES);
		[previousController removeFromParentViewController]; // this calls [previousController didMoveToParentViewController:nil] for us
	}
}

#pragma mark - Gesture handlers

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
	if ([self isAnimating])
		return;
	
	CGPoint tapPoint = [gestureRecognizer locationInView:self.view];
	BOOL isHorizontal = [self orientation] == OLFlipViewControllerOrientationHorizontal;
	CGFloat value = isHorizontal? tapPoint.x : tapPoint.y;
	CGFloat dimension = isHorizontal? self.view.bounds.size.width : self.view.bounds.size.height;
	NSLog(@"Tap to flip");
	if (value <= MARGIN)
		[self gotoPreviousPage];
	else if (value >= dimension - MARGIN)
		[self gotoNextPage];
}

- (void)handleSwipePrev:(UIGestureRecognizer *)gestureRecognizer
{
	if ([self isAnimating])
		return;
	
	NSLog(@"Swipe to previous page");
	[self gotoPreviousPage];
}

- (void)handleSwipeNext:(UIGestureRecognizer *)gestureRecognizer
{
	if ([self isAnimating])
		return;
	
	NSLog(@"Swipe to next page");
	[self gotoNextPage];
}

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer
{
    UIGestureRecognizerState state = [gestureRecognizer state];
	CGPoint currentPosition = [gestureRecognizer locationInView:self.view];
	
	if (state == UIGestureRecognizerStateBegan)
	{
		if ([self isAnimating])
			return;
		
		// See if touch started near one of the edges, in which case we'll pan a page turn
		BOOL isHorizontal = [self orientation] == OLFlipViewControllerOrientationHorizontal;
		CGFloat value = isHorizontal? currentPosition.x : currentPosition.y;
		CGFloat dimension = isHorizontal? self.view.bounds.size.width : self.view.bounds.size.height;
		if (value <= MARGIN)
		{
			if (![self startFlipWithDirection:OLFlipViewControllerDirectionReverse])
				return;
		}
		else if (value >= dimension - MARGIN)
		{
			if (![self startFlipWithDirection:OLFlipViewControllerDirectionForward])
				return;
		}
		else
		{
			// Do nothing for now, but it might become a swipe later
			return;
		}
		
		[self setPanning:YES];
		[self setPanStart:currentPosition];
		[self setLastPanPosition:currentPosition];
	}
	
	if ([self isPanning] && state == UIGestureRecognizerStateChanged)
	{
		CGFloat progress = [self progressFromPosition:currentPosition];
		CGPoint vel = [gestureRecognizer velocityInView:gestureRecognizer.view];
		//NSLog(@"Pan position changed, velocity = %@", NSStringFromCGPoint(vel));
		CGFloat velocityComponent = (self.orientation == OLFlipViewControllerOrientationHorizontal)? vel.x : vel.y;
		CGFloat velocityMinorComponent = (self.orientation == OLFlipViewControllerOrientationHorizontal)? vel.y : vel.x;
		// ignore the velocity if it's mostly in the off-axis direction (e.g. don't consider left velocity if swipe is mostly up or even diagonally up-left)
		if (fabs(velocityMinorComponent) > fabs(velocityComponent))
			velocityComponent = 0;
		
		if (![self isRubberbanding] && (velocityComponent < -SWIPE_ESCAPE_VELOCITY || velocityComponent > SWIPE_ESCAPE_VELOCITY))
		{
			// Detected a swipe to the left
			NSLog(@"Escape velocity reached.");
			BOOL shouldFallBack = (velocityComponent < -SWIPE_ESCAPE_VELOCITY)? self.direction != OLFlipViewControllerDirectionForward : self.direction == OLFlipViewControllerDirectionForward;
			[self setPanning:NO];
			
			// finish the remaining animation, but from the last touch position
			[self finishPan:shouldFallBack];
		}
		else
		{
			if (progress < 1)
				[self.flipTransition setStage:OLFlipAnimationStage1 progress:progress];
			else
				[self.flipTransition setStage:OLFlipAnimationStage2 progress:progress - 1];
			[self setLastPanPosition:currentPosition];
		}
	}
	
	if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
	{
		CGPoint vel = [gestureRecognizer velocityInView:gestureRecognizer.view];
		CGFloat velocityComponent = (self.orientation == OLFlipViewControllerOrientationHorizontal)? vel.x : vel.y;
		CGFloat velocityMinorComponent = (self.orientation == OLFlipViewControllerOrientationHorizontal)? vel.y : vel.x;
		// ignore the velocity if it's mostly in the off-axis direction (e.g. don't consider left velocity if swipe is mostly up or even diagonally up-left)
		if (fabs(velocityMinorComponent) > fabs(velocityComponent))
			velocityComponent = 0;
		
		//NSLog(@"Terminal velocity = %@", NSStringFromCGPoint(vel));
		if ([self isPanning])
        {
			// If moving slowly, let page fall either forward or back depending on where we were
			BOOL shouldFallBack = [self isFlipFrontPage];
			
			if ([self isRubberbanding])
				shouldFallBack = YES;
			// But, if user was swiping in an appropriate direction, go ahead and honor that
			else if (velocityComponent < -SWIPE_THRESHOLD)
			{
				// Detected a swipe to the left/top
				shouldFallBack = self.direction != OLFlipViewControllerDirectionForward;
			}
			else if (velocityComponent > SWIPE_THRESHOLD)
			{
				// Detected a swipe to the right/bottom
				shouldFallBack = self.direction == OLFlipViewControllerDirectionForward;
			}				
			
			// finish Animation
			[self finishPan:shouldFallBack];
        }
	}
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	// don't recognize any further gestures if we're in the middle of animating a page-turn
	if ([self isAnimating])
		return NO;
	
	if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] || [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
	{
		// for taps and pans, only handle if started within margin, otherwise don't receive so that the content may handle it
		CGPoint tapPoint = [touch locationInView:self.view];
		BOOL isHorizontal = [self orientation] == OLFlipViewControllerOrientationHorizontal;
		CGFloat value = isHorizontal? tapPoint.x : tapPoint.y;
		CGFloat dimension = isHorizontal? self.view.bounds.size.width : self.view.bounds.size.height;
		return (value <= MARGIN || value >= dimension - MARGIN);
	}
	
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	// don't recognize simultaneously with scroll view gestures in content area
	if ([[otherGestureRecognizer view] isKindOfClass:[UIScrollView class]])
		return NO;
	
	// Allow simultanoues pan & swipe recognizers
	return YES;
}

#pragma mark - Private instance methods

- (CGFloat)progressFromPosition:(CGPoint)position
{
	// Determine where we are in our page turn animation
	// 0 - 1 means flipping the front-side of the page
	// 1 - 2 means flipping the back-side of the page
	BOOL isForward = ([self direction] == OLFlipViewControllerDirectionForward);
	BOOL isVertical = ([self orientation] == OLFlipViewControllerOrientationVertical);
	
	CGFloat positionValue = isVertical? position.y : position.x;
	CGFloat startValue = isVertical? self.panStart.y : self.panStart.x;
	CGFloat dimensionValue = isVertical? self.view.frame.size.height : self.view.frame.size.width;
	CGFloat difference = positionValue - startValue;
	CGFloat halfWidth = fabs(startValue - (dimensionValue / 2));
	CGFloat progress = difference / halfWidth * (isForward? - 1 : 1);
	if ([self isRubberbanding])
	{
		if ((difference > 0) == isForward)
			progress = 0;
		else
		{
			// version of Hill equation (AKA Langmuir absorption equation), y = Kx^n / (1 + Kx^n)
			// basically I want it to get increasingly more difficult to pull the page until we reach a maximum progress of 0.667
			halfWidth += MAX(halfWidth * 2, halfWidth + (dimensionValue / 2));
			CGFloat K = 1/(halfWidth * 3); // K & n can be adjusted to get different reaction curves
			CGFloat n = 1.6667;
			CGFloat temp = K * powf(fabs(difference), n);
			progress = 0.667 * (temp/ (1 + temp)); // scale it to never get past 0.6667 (normally it is asymptotic to 1)
		}
	}
	
	//NSLog(@"Difference = %.2f, Half width = %.2f, rawProgress = %.4f", difference, halfWidth, progress);
	if (progress < 0)
		progress = 0;
	if (progress > 2)
		progress = 2;
	return progress;
}

- (void)finishPan:(BOOL)shouldFallBack
{
	// finishAnimation
	CGFloat fromProgress = [self progressFromPosition:[self lastPanPosition]];
	if (shouldFallBack != [self isFlipFrontPage])
	{
		// 2-stage animation (we're swiping either forward or back)
		if (([self isFlipFrontPage] && fromProgress > 1) || (![self isFlipFrontPage] && fromProgress < 1))
			fromProgress = 1;
		if (fromProgress > 1)
			fromProgress -= 1;
	}
	else
	{
		// 1-stage animation
		if (!shouldFallBack)
			fromProgress -= 1;
	}
	[[self flipTransition] animateFromProgress:fromProgress shouldFallBack:shouldFallBack completion:^(BOOL finished) {
		[self endFlipAnimation:finished transitionCompleted:!shouldFallBack completion:nil];
	}];
}

- (BOOL)startFlipWithDirection:(OLFlipViewControllerDirection)direction
{
	if (![self dataSource])
		return NO;
	
	UIViewController *destinationController = (direction == OLFlipViewControllerDirectionForward)? 
	[[self dataSource] flipViewController:self viewControllerAfterViewController:[self viewController]] : 
	[[self dataSource] flipViewController:self viewControllerBeforeViewController:[self viewController]];
	
	if (!destinationController)
	{
		// we're at first or last page, but allow user to lift up current page a bit,
		// so we'll pass in a dummy blank page to show behind
		[self setRubberbanding:YES];
	}
	
	[self setGestureDriven:YES];
	[self startFlipToViewController:destinationController fromViewController:[self viewController] withDirection:direction];
	
	return YES;
}

- (void)startFlipToViewController:(UIViewController *)destinationController fromViewController:(UIViewController *)sourceController withDirection:(OLFlipViewControllerDirection)direction
{
	BOOL isForward = (direction == OLFlipViewControllerDirectionForward);
	BOOL isVertical = ([self orientation] == OLFlipViewControllerOrientationVertical);
	[self setSourceController:sourceController];
	[self setDestinationController:destinationController];
	[self setDirection:direction];
	self.flipTransition = [[OLFlipTransition alloc] initWithSourceView:[sourceController view] 
													   destinationView:[destinationController view] 
															  duration:0.5 
																 style:((isForward? OLFlipStyleDefault : OLFlipStyleDirectionBackward) | (isVertical? OLFlipStyleOrientationVertical : OLFlipStyleDefault))
													  completionAction:OLTransitionActionAddRemove];
	
	[self.flipTransition buildLayers];
	
	// set the back page in the vertical position (midpoint of animation)
	[self.flipTransition prepareForStage2];
}

- (void)endFlipAnimation:(BOOL)animationFinished transitionCompleted:(BOOL)transitionCompleted completion:(void (^)(BOOL finished))completion
{
	BOOL didStartAsPan = [self animationDidStartAsPan];
	// clear some flags
	[self setFlipTransition:nil];
	[self setPanning:NO];
	[self setAnimationDidStartAsPan:NO];
	
	if (transitionCompleted)
	{
		// If page turn was completed, then we need to send our various notifications as per the Containment API
		if (didStartAsPan)
		{
			// these weren't sent at beginning (because we couldn't know beforehand 
			// whether the gesture would result in a page turn or not)
			[self addChildViewController:self.destinationController]; // this calls [self.destinationController willMoveToParentViewController:self] for us
			[self setChildViewController:self.destinationController];
			[self.sourceController willMoveToParentViewController:nil];
		}
		
		// final set of containment notifications
		[self.destinationController didMoveToParentViewController:self];
		[self.sourceController removeFromParentViewController]; // this calls [self.sourceController didMoveToParentViewController:nil] for us
	}
	
	if (completion)
		completion(animationFinished);
	
	if ([self isGestureDriven])
	{
		// notify delegate that we finished the page turn animation, indicating whether the user actually completed the page turn
		// or not, and also whether the animation ran to completion or not
		if ([[self delegate] respondsToSelector:@selector(flipViewController:didFinishAnimating:previousViewController:transitionCompleted:)])
		{
			[[self delegate] flipViewController:self didFinishAnimating:animationFinished previousViewController:self.sourceController transitionCompleted:transitionCompleted];
		}
		
		// Send notification.
		id previousController = self.sourceController? self.sourceController : [NSNull null];
		id newController = self.destinationController? self.destinationController : [NSNull null];
		NSDictionary *info = [NSDictionary dictionaryWithObjects:
							  [NSArray arrayWithObjects:[NSNumber numberWithBool:animationFinished], [NSNumber numberWithBool:transitionCompleted], previousController, newController, nil]
													  forKeys:
							  [NSArray arrayWithObjects:OLAnimationFinishedKey, OLTransitionCompletedKey, OLPreviousControllerKey, OLNewControllerKey, nil]];
		[[NSNotificationCenter defaultCenter] postNotificationName:OLFlipViewControllerDidFinishAnimatingNotification
															object:self
														  userInfo:info];
	}
	
	// clear remaining flags
	self.sourceController = nil;
	self.destinationController = nil;
	[self setGestureDriven:NO];
	[self setRubberbanding:NO];
}

- (void)gotoPreviousPage
{
	if (![self dataSource])
		return;
	
	UIViewController *previousController = [[self dataSource] flipViewController:self viewControllerBeforeViewController:[self viewController]];
	if (!previousController)
	{
		[self setRubberbanding:YES];
		[self startFlipToViewController:nil fromViewController:self.childViewController withDirection:OLFlipViewControllerDirectionReverse];
		[self.flipTransition performRubberband:^(BOOL finished) {
			[self endFlipAnimation:finished transitionCompleted:NO completion:nil];
		}];
		return;
	}
	
	[self setGestureDriven:YES];
	[self setViewController:previousController direction:OLFlipViewControllerDirectionReverse animated:YES completion:nil];
}

- (void)gotoNextPage
{
	if (![self dataSource])
		return;
	
	UIViewController *nextController = [[self dataSource] flipViewController:self viewControllerAfterViewController:[self viewController]];
	if (!nextController)
	{
		[self setRubberbanding:YES];
		[self startFlipToViewController:nil fromViewController:self.childViewController withDirection:OLFlipViewControllerDirectionForward];
		[self.flipTransition performRubberband:^(BOOL finished) {
			[self endFlipAnimation:finished transitionCompleted:NO completion:nil];
		}];
		return;
	}
	
	[self setGestureDriven:YES];
	[self setViewController:nextController direction:OLFlipViewControllerDirectionForward animated:YES completion:nil];	
}

@end
