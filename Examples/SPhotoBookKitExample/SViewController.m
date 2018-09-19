//
//  Copyright © 2018 ZhiweiSun. All rights reserved.
//
//  File name: SViewController.m
//  Author:    ZhiweiSun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      09/19/2018: Created by Cyrex on 09/19/2018
//

#import "SViewController.h"
#import <SPhotoBookKit/SPhotoBookKit.h>

@interface SViewController () <SPBookDataSource, SPBookDelegate>

@property (nonatomic, strong) SPBookViewController *bookViewController;

@property (nonatomic, strong) UIButton *nextButton;

@end

@implementation SViewController
#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.
//    [self addChildViewController:self.bookViewController];
//    [self.view addSubview:self.bookViewController.view];
//    [self.bookViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.center.equalTo(self.view);
//        make.width.mas_equalTo(270);
//        make.height.mas_equalTo(202);
//    }];

//    [self.bookViewController willMoveToParentViewController:self];
//    [self.bookViewController didMoveToParentViewController:self];

//    [self.view addSubview:self.nextButton];
//    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(self.view).offset(-20);
//        make.centerX.equalTo(self.view);
//        make.width.mas_equalTo(90);
//        make.height.mas_equalTo(40);
//    }];
}


#pragma mark - Prvate Methods
- (void)scrollToNextPage:(NSInteger)index {
    NSInteger nextIndex = index + 2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.bookViewController scrollBookViewControllerToIndex:index];
//        [self.bookViewController scrollBookViewControllerToIndex:index withCompletion:nil];

        if (nextIndex < [self.bookViewController.dataSource numberOfPhotoInBookViewController:self.bookViewController] - 1) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self scrollToNextPage:nextIndex];
            });
        }
    });
}


#pragma makr - Action Methods
- (void)didClickNextButton {
    [self scrollToNextPage:0];
}


#pragma mark - SPBookDataSource
- (NSInteger)numberOfPhotoInBookViewController:(SPBookViewController *)bookViewController {
    return 22;
}

- (SPBookContentViewController *)bookViewController:(SPBookViewController *)bookViewController
                          contentViewControllerForIndex:(NSInteger)index {

    SPBookContentViewController *vc = [[SPBookContentViewController alloc] initWithIndex:index];
    vc.contentImage = [UIImage imageNamed:[NSString stringWithFormat:@"image_book_template_%@", @(index + 1)]];

    return vc;
}

- (void)bookViewController:(SPBookViewController *)bookViewController coverImageView:(SPBookCoverView *)coverView {
    NSString *url = @"https://storage.googleapis.com/makefriends-8fd6d.appspot.com/photobook/cover/image_book_cover_1.png";
//    [coverView.coverImageView sd_setImageWithURL:[NSURL URLWithString:url]];
    //    coverView.coverImageView.image = [UIImage imageNamed:@"image_book_cover_placeholder"];
}


#pragma mark - SPBookDelegate
- (void)didTapcCoverImageView:(SPBookViewController *)bookViewController {

}

- (BOOL)shouldCloseBackCoverForBookViewController:(SPBookViewController *)bookViewController {
    return NO;
}


#pragma makr - Getters
- (SPBookViewController *)bookViewController {
    if (!_bookViewController) {
        _bookViewController = [[SPBookViewController alloc] init];
        _bookViewController.delegate   = self;
        _bookViewController.dataSource = self;
    }

    return _bookViewController;
}

- (UIButton *)nextButton {
    if (!_nextButton) {
        _nextButton = [[UIButton alloc] init];
        [_nextButton setTitle:@"Next" forState:UIControlStateNormal];
        [_nextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_nextButton addTarget:self action:@selector(didClickNextButton) forControlEvents:UIControlEventTouchUpInside];
    }

    return _nextButton;
}

@end
