//
//  Copyright © 2018 ZhiweiSun. All rights reserved.
//
//  File name: SPhotoBookViewController.m
//  Author:    ZhiweiSun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2018/3/6: Created by Cyrex on 2018/3/6
//

#import "SPhotoBookViewController.h"
#import "SPhotobookContentViewController.h"

#import "OLFlipTransition.h"
#import "Masonry.h"

#import "UIImage+SPhotoBook.h"

static const NSUInteger kTagLeft = 10;
static const NSUInteger kTagRight = 20;
static const CGFloat kBookAnimationTime = 0.8;
static const CGFloat kBookEdgePadding = 38;



@interface OLFlipTransition (Private)

- (void)animateFlip1:(BOOL)isFallingBack fromProgress:(CGFloat)fromProgress toProgress:(CGFloat)toProgress withCompletion:(void (^)(BOOL finished))completion;
- (void)animateFlip2:(BOOL)isFallingBack fromProgress:(CGFloat)fromProgress withCompletion:(void (^)(BOOL finished))completion;
- (void)transitionDidComplete:(BOOL)completed;
- (void)cleanupLayers;

@end

@interface SPhotoBookViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate,UIGestureRecognizerDelegate>

@property (assign, nonatomic) BOOL animating;
@property (assign, nonatomic) BOOL bookClosed;
@property (assign, nonatomic) BOOL haveSeenViewDidAppear;
@property (assign, nonatomic) BOOL stranded;
@property (assign, nonatomic) BOOL userHasOpenedBook;

@property (strong, nonatomic) UIDynamicAnimator* dynamicAnimator;
@property (strong, nonatomic) UIDynamicItemBehavior* inertiaBehavior;

@property (strong, nonatomic) UIView *bookCover;

@property (strong, nonatomic) UIImageView *bookImageView;
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UIView *fakeShadowView;
@property (strong, nonatomic) UIView *openbookView;

@property (nonatomic, strong) UIPageViewController *pageViewController;

@property (strong, nonatomic) UIPanGestureRecognizer *pageControllerPanGesture;

@end

@implementation SPhotoBookViewController
#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.containerView addSubview:self.bookCover];
    [self.bookCover mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    [self.containerView addSubview:self.openbookView];
    [self.openbookView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];

    [self.openbookView addSubview:self.fakeShadowView];
    [self.openbookView addSubview:self.bookImageView];
    [self.bookImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.openbookView);
    }];

    [self addChildViewController:self.pageViewController];
    [self.openbookView addSubview:self.pageViewController.view];
//    [self.openbookView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.pageViewController.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeHeight multiplier: constant:0]];
//    [self.openbookView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.pageViewController.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
//
//    [self.openbookView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.pageViewController.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeWidth multiplier:1 - (2 * .031951641) constant:0]];
//    [self.openbookView.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.pageViewController.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.openbookView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];

    [self.pageViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.openbookView);
        make.centerY.equalTo(self.openbookView);
        make.height.equalTo(self.openbookView).multipliedBy(1 - (2 * .021573604));
        make.width.equalTo(self.openbookView).multipliedBy(1 - (2 * .031951641));
    }];

    [self.pageViewController willMoveToParentViewController:self];
    [self.pageViewController didMoveToParentViewController:self];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(onTapGestureRecognized:)];
    tapGesture.delegate = self;

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(onPanGestureRecognized:)];
    panGesture.delegate = self;

    [self.pageViewController.view addGestureRecognizer:tapGesture];
    [self.pageViewController.view addGestureRecognizer:panGesture];

    self.containerView.layer.shadowOffset = CGSizeMake(-10, 10);
    self.containerView.layer.shadowRadius = 5;
    self.containerView.layer.shadowOpacity = 0.25;
    self.containerView.layer.shouldRasterize = YES;
    self.containerView.layer.rasterizationScale = [UIScreen mainScreen].scale;

    self.bookImageView.layer.masksToBounds = YES;
    self.bookImageView.layer.cornerRadius  = 3;

    for (UIGestureRecognizer *gesture in self.pageViewController.gestureRecognizers){
        gesture.delegate = self;
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]){
            self.pageControllerPanGesture = (UIPanGestureRecognizer *)gesture;
        }
    }

    if (!self.startOpen) {
        [self setUpBookCoverViewForFrontCover:YES];
        self.bookCover.hidden = NO;
        self.containerView.layer.shadowOpacity = 0;

        UIView *closedPage = [self.bookCover viewWithTag:kTagRight];
        closedPage.layer.shadowOffset = CGSizeMake(-10, 10);
        closedPage.layer.shadowRadius = 5;
        closedPage.layer.shadowOpacity = 0.25;
        closedPage.layer.shouldRasterize = YES;
        closedPage.layer.rasterizationScale = [UIScreen mainScreen].scale;

        self.containerView.layer.shadowOpacity = 0.0;
        self.bookClosed = YES;

        self.openbookView.hidden = YES;

        self.fakeShadowView.layer.masksToBounds = YES;
        self.fakeShadowView.layer.cornerRadius  = 3;
    }
}


#pragma mark - Public Methods
- (void)scrollBookViewControllerToIndex:(NSInteger)index {
    index = (index % 2) ? index - 1 : index;

    if (self.bookClosed) {
        [self autoOpenBook];
    } else {
        if (index > [self.dataSource numberOfPhotoInBookViewController:self] - 1) {
            return ;
        }
        NSInteger currentIndex = ((SPhotobookContentViewController *)(self.pageViewController.viewControllers.firstObject)).index;
        if (index > currentIndex) {
            [self.pageViewController setViewControllers:@[[self.dataSource bookViewController:self contentViewControllerForIndex:index],
                                                          [self.dataSource bookViewController:self contentViewControllerForIndex:index + 1]]
                                              direction:UIPageViewControllerNavigationDirectionForward
                                               animated:YES
                                             completion:nil];
        } else if (index < currentIndex) {
            [self.pageViewController setViewControllers:@[[self.dataSource bookViewController:self contentViewControllerForIndex:index],
                                                          [self.dataSource bookViewController:self contentViewControllerForIndex:index + 1]]
                                              direction:UIPageViewControllerNavigationDirectionReverse
                                               animated:YES
                                             completion:nil];
        }
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];

    if (!self.haveSeenViewDidAppear){
        if (![self isLandscape]){
            if ((self.containerView.frame.size.width > self.view.frame.size.width - kBookEdgePadding * 2)){
                self.containerView.transform = CGAffineTransformMakeTranslation([self xTrasformForBookAtRightEdge], 0);
            } else {
                ;
            }
        }
    }
    if (self.bookClosed){
        self.containerView.transform = CGAffineTransformMakeTranslation(-self.containerView.frame.size.width / 4.0, 0);
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.haveSeenViewDidAppear = YES;

    if (self.bookClosed){
        [self tease];
    }
}
- (void)tease{
    if (self.animating || self.userHasOpenedBook){
        return;
    }

    self.animating = YES;
    OLFlipStyle style = OLFlipStyleDefault;
    OLFlipTransition *flipTransition = [[OLFlipTransition alloc] initWithSourceView:self.bookCover destinationView:self.openbookView duration:0.5 timingCurve:UIViewAnimationCurveEaseOut completionAction:OLTransitionActionNone];
    flipTransition.style = style;

    [flipTransition buildLayers];
    CGFloat maxProgress = 0.5;
    [flipTransition setRubberbandMaximumProgress:maxProgress/2.0];
    [flipTransition setDuration:[flipTransition duration] * 1 / maxProgress]; // necessary to arrive at the dersired total duration
    [flipTransition animateFlip1:NO fromProgress:0 toProgress:maxProgress withCompletion:^(BOOL finished) {
        flipTransition.timingCurve = UIViewAnimationCurveEaseIn;
        [flipTransition animateFlip2:YES fromProgress:maxProgress withCompletion:^(BOOL finished) {
            [flipTransition cleanupLayers];
            [flipTransition transitionDidComplete:NO];
            self.animating = NO;

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self tease];
            });
        }];
    }];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    self.stranded = NO;
    self.containerView.transform = CGAffineTransformIdentity;
    if (size.width > size.height){
    
    } else{
    }

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setUpBookCoverViewForFrontCover:YES];
        if (size.width > size.height){
            self.containerView.transform = CGAffineTransformIdentity;
        } else{
            if (self.bookClosed && [self isBookAtStart]){
                self.containerView.transform = CGAffineTransformMakeTranslation([self xTrasformForBookAtRightEdge], 0);
            }
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.containerView.layer.shadowOpacity = 0;
    }];
}

- (BOOL)isLandscape{
    return self.view.frame.size.width > self.view.frame.size.height;
}

- (void)setUpBookCoverViewForFrontCover:(BOOL)front{
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(openBook:)];
    UIView *halfBookCoverImageContainer;

    if (front){
        halfBookCoverImageContainer = [self.bookCover viewWithTag:kTagRight];
        [self.bookCover viewWithTag:kTagLeft].hidden = YES;
        if (!halfBookCoverImageContainer){
            halfBookCoverImageContainer = [[UIView alloc] init];
            halfBookCoverImageContainer.tag = kTagRight;
            swipe.direction = UISwipeGestureRecognizerDirectionLeft;

            UIImage *rightCoverImage = nil;
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(rightCoverImageForBookViewController:)] ) {
                rightCoverImage = [self.dataSource rightCoverImageForBookViewController:self];
            }
            if (nil == rightCoverImage) {
                rightCoverImage = [UIImage imageNamedInSPhotoBook:@"book_cover_right"];
            }
            UIImageView *imageView = [[UIImageView alloc] initWithImage:rightCoverImage];
            imageView.contentMode = UIViewContentModeScaleAspectFill;

            imageView.layer.masksToBounds = YES;
            imageView.layer.cornerRadius  = 3;
            imageView.tag = 17;
            [halfBookCoverImageContainer addSubview:imageView];

            [self.bookCover addSubview:halfBookCoverImageContainer];

            halfBookCoverImageContainer.userInteractionEnabled = YES;
            [halfBookCoverImageContainer addGestureRecognizer:swipe];

            halfBookCoverImageContainer.layer.shadowOffset = CGSizeMake(-10, 10);
            halfBookCoverImageContainer.layer.shadowRadius = 5;
            halfBookCoverImageContainer.layer.shadowOpacity = 0.0;
            halfBookCoverImageContainer.layer.shouldRasterize = YES;
            halfBookCoverImageContainer.layer.rasterizationScale = [UIScreen mainScreen].scale;

            [self setupCoverContentInView:halfBookCoverImageContainer];
        }

        [halfBookCoverImageContainer removeConstraints:halfBookCoverImageContainer.constraints];
        UIView *view = halfBookCoverImageContainer;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];

        NSArray *visuals = @[@"H:[view]-0-|",
                             @"V:|-0-[view]-0-|"];


        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }

        [view.superview addConstraints:con];
        [view.superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeWidth multiplier:0.5 constant:1]];

        view = [halfBookCoverImageContainer viewWithTag:17];
        [view removeConstraints:view.constraints];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        views = NSDictionaryOfVariableBindings(view);
        con = [[NSMutableArray alloc] init];

        visuals = @[@"H:|-0-[view]-0-|",
                    @"V:|-0-[view]-0-|"];


        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }

        [view.superview addConstraints:con];

        UIView *coverImageView = [halfBookCoverImageContainer viewWithTag:18];
        [halfBookCoverImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:coverImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:halfBookCoverImageContainer attribute:NSLayoutAttributeWidth multiplier:0.8 constant:0]];
        [halfBookCoverImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:coverImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:halfBookCoverImageContainer attribute:NSLayoutAttributeHeight multiplier:0.9 constant:0]];
        [halfBookCoverImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:halfBookCoverImageContainer attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:coverImageView attribute:NSLayoutAttributeCenterX multiplier:0.97 constant:0]];
        [halfBookCoverImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:coverImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:halfBookCoverImageContainer attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [self.bookCover viewWithTag:kTagRight].hidden = NO;
    } else {
        [self.bookCover viewWithTag:kTagRight].hidden = YES;
        halfBookCoverImageContainer = [self.bookCover viewWithTag:kTagLeft];
        if (!halfBookCoverImageContainer){
            halfBookCoverImageContainer = [[UIView alloc] init];
            halfBookCoverImageContainer.tag = kTagLeft;
            swipe.direction = UISwipeGestureRecognizerDirectionRight;
            [self.bookCover addSubview:halfBookCoverImageContainer];
            halfBookCoverImageContainer.userInteractionEnabled = YES;
            [halfBookCoverImageContainer addGestureRecognizer:swipe];

            UIImage *leftCoverImage = nil;
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(leftCoverImageForBookViewController:)] ) {
                leftCoverImage = [self.dataSource leftCoverImageForBookViewController:self];
            }
            if (nil == leftCoverImage) {
                leftCoverImage = [UIImage imageNamedInSPhotoBook:@"book_cover_left"];
            }
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:leftCoverImage];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.layer.masksToBounds = YES;
            imageView.layer.cornerRadius  = 3;
            [halfBookCoverImageContainer addSubview:imageView];

            halfBookCoverImageContainer.layer.shadowOffset = CGSizeMake(-10, 10);
            halfBookCoverImageContainer.layer.shadowRadius = 5;
            halfBookCoverImageContainer.layer.shadowOpacity = 0.0;
            halfBookCoverImageContainer.layer.shouldRasterize = YES;
            halfBookCoverImageContainer.layer.rasterizationScale = [UIScreen mainScreen].scale;
        }


        halfBookCoverImageContainer.frame = CGRectMake(0, 0, self.bookCover.frame.size.width / 2.0, self.bookCover.frame.size.height);
        [[[halfBookCoverImageContainer subviews] firstObject] setFrame:halfBookCoverImageContainer.frame];
        [self.bookCover viewWithTag:kTagLeft].hidden = NO;
    }
}

- (void)setupCoverContentInView:(UIView *)halfBookCoverImageContainer{
    UIImageView *coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bookCover.frame.size.width / 2.0, self.bookCover.frame.size.height)];
//    coverImageView.delegate = self;
    self.coverImageView = coverImageView;
    self.coverImageView.image = [self.dataSource userSubCoverImageForBookViewController:self];
    coverImageView.backgroundColor = [UIColor clearColor];
    coverImageView.tag = 18;
    [halfBookCoverImageContainer addSubview:coverImageView];
    coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
}


#pragma mark - UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {

    SPhotobookContentViewController *vc = (SPhotobookContentViewController *)viewController;
    NSUInteger index = vc.index - 1;
    if (vc.index == 0) {
        return nil;
    }
    
    return [self.dataSource bookViewController:self contentViewControllerForIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {

    SPhotobookContentViewController *vc = (SPhotobookContentViewController *)viewController;
    NSUInteger index = (vc.index + 1);
    if (index >= [self.dataSource numberOfPhotoInBookViewController:self]){
        return nil;
    }

    return [self.dataSource bookViewController:self contentViewControllerForIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return [self.dataSource numberOfPhotoInBookViewController:self];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 2;
}


#pragma mark - UIPageViewControllerDelegate
- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
    
    self.animating = YES;
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers
       transitionCompleted:(BOOL)completed {

    self.animating = NO;
    if (completed){
        SPhotobookContentViewController *vc1 = [pageViewController.viewControllers firstObject];
        [UIView animateWithDuration:kBookAnimationTime/2.0 animations:^{
            if ([(SPhotobookContentViewController *)[previousViewControllers firstObject] index] < vc1.index){
                self.containerView.transform = CGAffineTransformIdentity;
            } else if (![self isContainerViewAtRightEdge:NO]){
                self.containerView.transform = CGAffineTransformMakeTranslation([self xTrasformForBookAtRightEdge], 0);
            }
        }];
    }
}

//- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController
//                   spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
//
//    return UIPageViewControllerSpineLocationMid;
//}


#pragma mark - Getters
- (UIPageViewController *)pageViewController {
    if (!_pageViewController) {
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl

                                                          navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
 options:@{UIPageViewControllerOptionSpineLocationKey : [NSNumber numberWithInt:UIPageViewControllerSpineLocationMid]}];
        [_pageViewController setViewControllers:@[[self.dataSource bookViewController:self contentViewControllerForIndex:0],
                                                  [self.dataSource bookViewController:self contentViewControllerForIndex:1]]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
        _pageViewController.delegate = self;
        _pageViewController.dataSource = self;

    }

    return _pageViewController;
}

- (CGFloat)xTrasformForBookAtRightEdge {
    CGFloat temp = self.view.frame.size.width - self.containerView.frame.size.width - kBookEdgePadding * 2;
    NSLog(@"%@", @(temp));
    return temp;
}

- (BOOL)isContainerViewAtRightEdge:(BOOL)useFrame{
//    if (!useFrame){
//        return self.containerView.transform.tx <= [self xTrasformForBookAtRightEdge] && !self.stranded;
//    } else{
//        return self.containerView.frame.origin.x - kBookEdgePadding <= [self xTrasformForBookAtRightEdge];
//    }
    return YES;
}

- (BOOL)isContainerViewAtLeftEdge:(BOOL)useFrame{
//    if (!useFrame){
//        return self.containerView.transform.tx >= 0 && !self.stranded;
//    } else{
//        return self.containerView.center.x - self.containerView.frame.size.width / 2  - kBookEdgePadding >= 0;
//    }
    return YES;
}

- (BOOL)isBookAtStart {
    SPhotobookContentViewController *vc1 = [self.pageViewController.viewControllers firstObject];
    return vc1.index == 0;
}

- (BOOL)isBookAtEnd {
    SPhotobookContentViewController *vc2 = [self.pageViewController.viewControllers lastObject];
    return vc2.index == [self.dataSource numberOfPhotoInBookViewController:self] - 1;
}

- (void)openBook:(UIGestureRecognizer *)sender{
    if (self.animating){
        return;
    }
    self.animating = YES;
    self.userHasOpenedBook = YES;

    [UIView animateWithDuration:kBookAnimationTime animations:^{
        //TODO seld.dataarrya.cout
        if (1 != 0){
            self.containerView.transform = CGAffineTransformIdentity;
        }
    } completion:^(BOOL completed){}];
    OLFlipStyle style = sender.view.tag == kTagRight ? OLFlipStyleDefault : OLFlipStyleDirectionBackward;
    OLFlipTransition *flipTransition = [[OLFlipTransition alloc] initWithSourceView:self.bookCover destinationView:self.openbookView duration:kBookAnimationTime timingCurve:UIViewAnimationCurveEaseInOut completionAction:OLTransitionActionNone];
    flipTransition.style = style;
    [flipTransition perform:^(BOOL finished){
        self.bookClosed = NO;

        self.openbookView.hidden = NO;

        //Fade out shadow of the half-book.
        UIView *closedPage = [self.bookCover viewWithTag:sender.view.tag];
        CABasicAnimation *showAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        showAnim.fromValue = [NSNumber numberWithFloat:0.25];
        showAnim.toValue = [NSNumber numberWithFloat:0.0];
        showAnim.duration = kBookAnimationTime/4.0;
        showAnim.removedOnCompletion = NO;
        showAnim.fillMode = kCAFillModeForwards;
        [closedPage.layer addAnimation:showAnim forKey:@"shadowOpacity"];

        //Fade in shadow of the book cover
        CABasicAnimation *hideAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        hideAnim.fromValue = [NSNumber numberWithFloat:0.0];
        hideAnim.toValue = [NSNumber numberWithFloat:0.25];
        hideAnim.duration = kBookAnimationTime/4.0;
        hideAnim.removedOnCompletion = NO;
        hideAnim.fillMode = kCAFillModeForwards;
        [self.containerView.layer addAnimation:hideAnim forKey:@"shadowOpacity"];

        CABasicAnimation *cornerAnim = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        cornerAnim.fromValue = @3;
        cornerAnim.toValue = @0;
        cornerAnim.duration = kBookAnimationTime/4.0;
        cornerAnim.removedOnCompletion = NO;
        cornerAnim.fillMode = kCAFillModeForwards;
        [self.fakeShadowView.layer addAnimation:cornerAnim forKey:@"cornerRadius"];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kBookAnimationTime/4.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.animating = NO;
            self.containerView.layer.shadowOpacity = 0.25;
            self.bookCover.hidden = YES;
        });
    }];
}

- (void)autoOpenBook {
    if (self.animating){
        return;
    }
    self.animating = YES;
    self.userHasOpenedBook = YES;
    
    [UIView animateWithDuration:kBookAnimationTime animations:^{
        //TODO seld.dataarrya.cout
        if (1 != 0){
            self.containerView.transform = CGAffineTransformIdentity;
        }
    } completion:^(BOOL completed){}];
    OLFlipStyle style = OLFlipStyleDefault;
    OLFlipTransition *flipTransition = [[OLFlipTransition alloc] initWithSourceView:self.bookCover destinationView:self.openbookView duration:kBookAnimationTime timingCurve:UIViewAnimationCurveEaseInOut completionAction:OLTransitionActionNone];
    flipTransition.style = style;
    [flipTransition perform:^(BOOL finished){
        self.bookClosed = NO;
        
        self.openbookView.hidden = NO;
        
        //Fade out shadow of the half-book.
        UIView *closedPage = [self.bookCover viewWithTag:kTagRight];
        CABasicAnimation *showAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        showAnim.fromValue = [NSNumber numberWithFloat:0.25];
        showAnim.toValue = [NSNumber numberWithFloat:0.0];
        showAnim.duration = kBookAnimationTime/4.0;
        showAnim.removedOnCompletion = NO;
        showAnim.fillMode = kCAFillModeForwards;
        [closedPage.layer addAnimation:showAnim forKey:@"shadowOpacity"];
        
        //Fade in shadow of the book cover
        CABasicAnimation *hideAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        hideAnim.fromValue = [NSNumber numberWithFloat:0.0];
        hideAnim.toValue = [NSNumber numberWithFloat:0.25];
        hideAnim.duration = kBookAnimationTime/4.0;
        hideAnim.removedOnCompletion = NO;
        hideAnim.fillMode = kCAFillModeForwards;
        [self.containerView.layer addAnimation:hideAnim forKey:@"shadowOpacity"];
        
        CABasicAnimation *cornerAnim = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        cornerAnim.fromValue = @3;
        cornerAnim.toValue = @0;
        cornerAnim.duration = kBookAnimationTime/4.0;
        cornerAnim.removedOnCompletion = NO;
        cornerAnim.fillMode = kCAFillModeForwards;
        [self.fakeShadowView.layer addAnimation:cornerAnim forKey:@"cornerRadius"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kBookAnimationTime/4.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.animating = NO;
            self.containerView.layer.shadowOpacity = 0.25;
            self.bookCover.hidden = YES;
        });
    }];
}


- (void)closeBookFrontForGesture:(UIPanGestureRecognizer *)sender{
    if (self.animating){
        return;
    }
    self.animating = YES;

    CGPoint translation = [sender translationInView:self.containerView];
    BOOL draggingRight = translation.x >= 0;

    [self setUpBookCoverViewForFrontCover:draggingRight];
    self.bookCover.hidden = NO;

    //Fade in shadow of the half-book.
    UIView *closedPage = [self.bookCover viewWithTag:kTagRight];
    CABasicAnimation *showAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    showAnim.fromValue = [NSNumber numberWithFloat:0.0];
    showAnim.toValue = [NSNumber numberWithFloat:0.25];
    showAnim.duration = kBookAnimationTime/4.0;
    [closedPage.layer addAnimation:showAnim forKey:@"shadowOpacity"];
    closedPage.layer.shadowOpacity = 0.25;

    //Fade out shadow of the book cover
    CABasicAnimation *hideAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    hideAnim.fromValue = [NSNumber numberWithFloat:0.25];
    hideAnim.toValue = [NSNumber numberWithFloat:0.0];
    hideAnim.duration = kBookAnimationTime/4.0;
    [self.containerView.layer addAnimation:hideAnim forKey:@"shadowOpacity"];
    self.containerView.layer.shadowOpacity = 0.0;

//    if (![self isContainerViewAtRightEdge:NO]){
        [UIView animateWithDuration:kBookAnimationTime animations:^{
            self.containerView.transform = CGAffineTransformMakeTranslation([self xTrasformForBookAtRightEdge], 0);
        }];
//    }

    OLFlipTransition *flipTransition = [[OLFlipTransition alloc] initWithSourceView:self.openbookView destinationView:self.bookCover duration:kBookAnimationTime timingCurve:UIViewAnimationCurveEaseInOut completionAction:OLTransitionActionShowHide];
    flipTransition.flippingPageShadowOpacity = 0;
    flipTransition.style = OLFlipStyleDirectionBackward;
    [flipTransition perform:^(BOOL finished){
        self.animating = NO;

        CABasicAnimation *cornerAnim = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        cornerAnim.fromValue = @0;
        cornerAnim.toValue = @3;
        cornerAnim.duration = kBookAnimationTime/4.0;
        cornerAnim.removedOnCompletion = NO;
        cornerAnim.fillMode = kCAFillModeForwards;
        [self.fakeShadowView.layer addAnimation:cornerAnim forKey:@"cornerRadius"];

        self.bookClosed = YES;
    }];
}
- (void)closeBookBackForGesture:(UIPanGestureRecognizer *)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(shouldCloseBackCoverForBookViewController:)]) {
        if (![self.delegate shouldCloseBackCoverForBookViewController:self]) {
            return ;
        }
    }

    if (self.animating){
        return;
    }
    self.animating = YES;

    CGPoint translation = [sender translationInView:self.containerView];
    BOOL draggingRight = translation.x >= 0;

    [self setUpBookCoverViewForFrontCover:draggingRight];
    self.bookCover.hidden = NO;

    // Turn off containerView shadow because we will be animating that. Will use bookCover view shadow for the duration of the animation.
    self.containerView.layer.shadowOpacity = 0;

    //Fade in shadow of the half-book.
    UIView *closedPage = [self.bookCover viewWithTag:kTagLeft];
    CABasicAnimation *showAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    showAnim.fromValue = [NSNumber numberWithFloat:0.0];
    showAnim.toValue = [NSNumber numberWithFloat:0.25];
    showAnim.duration = kBookAnimationTime/4.0;
    [closedPage.layer addAnimation:showAnim forKey:@"shadowOpacity"];
    closedPage.layer.shadowOpacity = 0.25;

    //Fade out shadow of the book cover
    CABasicAnimation *hideAnim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    hideAnim.fromValue = [NSNumber numberWithFloat:0.25];
    hideAnim.toValue = [NSNumber numberWithFloat:0.0];
    hideAnim.duration = kBookAnimationTime/4.0;
    [self.containerView.layer addAnimation:hideAnim forKey:@"shadowOpacity"];
    self.containerView.layer.shadowOpacity = 0.0;

    [UIView animateWithDuration:kBookAnimationTime/2.0
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.containerView.transform = CGAffineTransformIdentity;
                     } completion:^(BOOL finished){}];
    OLFlipTransition *flipTransition = [[OLFlipTransition alloc] initWithSourceView:self.openbookView destinationView:self.bookCover duration:kBookAnimationTime timingCurve:UIViewAnimationCurveEaseInOut completionAction:OLTransitionActionShowHide];
    flipTransition.flippingPageShadowOpacity = 0;
    flipTransition.style = OLFlipStyleDefault;
    [flipTransition perform:^(BOOL finished){
        self.animating = NO;
        self.fakeShadowView.layer.masksToBounds = YES;
        self.fakeShadowView.layer.cornerRadius  = 3;
    }];
    self.bookClosed = YES;
}


#pragma mark - Gesture recognizers
- (void)onCoverTapRecognized:(UITapGestureRecognizer *)sender{
    return;
}

- (void)onTapGestureRecognized:(UITapGestureRecognizer *)sender{
    return; //Prevent taps from going to the UIPageController
}

- (void)onPanGestureRecognized:(UIPanGestureRecognizer *)recognizer{
    if (self.animating){
        return;
    }
    CGPoint translation = [recognizer translationInView:self.containerView];
    BOOL draggingLeft = translation.x < 0;
    BOOL draggingRight = translation.x > 0;

    if (([self isContainerViewAtRightEdge:NO] && draggingLeft) || ([self isContainerViewAtLeftEdge:NO] && draggingRight)){
        if (draggingLeft && [self isBookAtEnd]) {
            recognizer.enabled = NO;
            recognizer.enabled = YES;
            [self closeBookBackForGesture:recognizer];
        }
        else if (draggingRight && [self isBookAtStart]) {
            recognizer.enabled = NO;
            recognizer.enabled = YES;
            [self closeBookFrontForGesture:recognizer];
        }
        return;
    }

    if ([self isContainerViewAtLeftEdge:NO] && [self isContainerViewAtRightEdge:NO]){
        return;
    }

    if (!(([self isContainerViewAtLeftEdge:NO] && draggingRight) || ([self isContainerViewAtRightEdge:NO] && draggingLeft))){

        self.containerView.transform = CGAffineTransformTranslate(self.containerView.transform, translation.x, 0);
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.containerView];

        if ([self isContainerViewAtRightEdge:NO]){
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9){
                recognizer.enabled = NO;
                recognizer.enabled = YES;
            }
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState  animations:^{
                self.containerView.transform = CGAffineTransformMakeTranslation(-self.containerView.frame.size.width + self.view.frame.size.width - kBookEdgePadding * 2, 0);
            } completion:NULL];
        }
        else if ([self isContainerViewAtLeftEdge:NO]){
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState  animations:^{
                self.containerView.transform = CGAffineTransformMakeTranslation(0, 0);
            } completion:NULL];
        }
    }

    if (recognizer.state == UIGestureRecognizerStateEnded){
        self.containerView.frame = CGRectMake(self.containerView.frame.origin.x + self.containerView.transform.tx, self.containerView.frame.origin.y, self.containerView.frame.size.width, self.containerView.frame.size.height);
        self.containerView.transform = CGAffineTransformIdentity;
        [self.dynamicAnimator addBehavior:self.inertiaBehavior];
        [self.inertiaBehavior addItem:self.containerView];
        [self.inertiaBehavior addLinearVelocity:CGPointMake([recognizer velocityInView:self.containerView].x, 0) forItem:self.containerView];
        self.inertiaBehavior.resistance = 3;
        __weak SPhotoBookViewController *welf = self;
        self.animating = YES;
        self.stranded = NO;
        [self.inertiaBehavior setAction:^{
            if ([welf isContainerViewAtRightEdge:YES] ){
                welf.animating = NO;
                [welf.inertiaBehavior removeItem:welf.containerView];
                [welf.dynamicAnimator removeBehavior:welf.inertiaBehavior];

                welf.containerView.transform = CGAffineTransformMakeTranslation(-welf.containerView.frame.size.width + welf.view.frame.size.width - kBookEdgePadding * 2, 0);

                [welf.view setNeedsLayout];
                [welf.view layoutIfNeeded];
                welf.stranded = NO;
            }
            else if ([welf isContainerViewAtLeftEdge:YES] && [self.inertiaBehavior linearVelocityForItem:welf.containerView].x > 0){
                welf.animating = NO;
                [welf.inertiaBehavior removeItem:welf.containerView];
                [welf.dynamicAnimator removeBehavior:welf.inertiaBehavior];

                welf.containerView.transform = CGAffineTransformIdentity;

                [welf.view setNeedsLayout];
                [welf.view layoutIfNeeded];
                welf.stranded = NO;
            }

            else if ([welf.inertiaBehavior linearVelocityForItem:welf.containerView].x < 15 && [welf.inertiaBehavior linearVelocityForItem:welf.containerView].x > -15 && !welf.stranded){
                welf.animating = NO;
                [welf.inertiaBehavior removeItem:welf.containerView];
                welf.stranded = YES;
            }
        }];
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] || [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]){
        return NO;
    }
    else if (([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) && ![otherGestureRecognizer.view isKindOfClass:[UICollectionView class]]){
        CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.containerView];
        BOOL draggingLeft = translation.x < 0;
        BOOL draggingRight = translation.x > 0;

        if (([self isContainerViewAtRightEdge:NO] && draggingLeft) || ([self isContainerViewAtLeftEdge:NO] && draggingRight)){
            return YES;
        }
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer == self.pageControllerPanGesture){
        CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.containerView];
        BOOL draggingLeft = translation.x < 0;
        BOOL draggingRight = translation.x > 0;
        if (draggingLeft && [self isBookAtEnd]){
            return NO;
        }
        if (draggingRight && [self isBookAtStart]){
            return NO;
        }
    }
    return !self.animating;
}

-(UIDynamicAnimator*) dynamicAnimator{
    if (!_dynamicAnimator) {
        _dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    }

    return _dynamicAnimator;
}

-(UIDynamicItemBehavior*) inertiaBehavior{
    if (!_inertiaBehavior){
        _inertiaBehavior = [[UIDynamicItemBehavior alloc] init];
    }

    return _inertiaBehavior;
}
- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
    }

    return _containerView;
}

- (UIView *)bookCover {
    if (!_bookCover) {
        _bookCover = [[UIView alloc] init];
    }

    return _bookCover;
}
- (UIView *)openbookView {
    if (!_openbookView) {
        _openbookView = [[UIView alloc] init];
    }

    return _openbookView;
}

- (UIView *)fakeShadowView {
    if (!_fakeShadowView) {
        _fakeShadowView = [[UIView alloc] init];
    }

    return _fakeShadowView;
}

- (UIImageView *)bookImageView {
    if (!_bookImageView) {
        _bookImageView = [[UIImageView alloc] init];
        _bookImageView.image = [UIImage imageNamedInSPhotoBook:@"book_bottom_cover"];
    }

    return _bookImageView;
}

@end
