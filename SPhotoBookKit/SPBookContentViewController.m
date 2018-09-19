//
//  Copyright © 2018 ZhiweiSun. All rights reserved.
//
//  File name: SPBookContentViewController.m
//  Author:    ZhiweiSun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2018/9/19: Created by Cyrex on 2018/9/19
//

#import "SPBookContentViewController.h"

#import "UIImage+SPhotoBook.h"

@interface SPBookContentViewController ()

@property (nonatomic, assign) BOOL isLeft;
@property (nonatomic, assign, readwrite) NSInteger index;

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation SPBookContentViewController
#pragma mark - Life Cycle
- (instancetype)initWithIndex:(NSInteger)index {
    if (self = [super init]) {
        self.index = index;
    }

    return self;
}

- (instancetype)init NS_UNAVAILABLE {
    return nil;
}

+ (instancetype)new NS_UNAVAILABLE {
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //    [self.view addSubview:self.imageView];
    //    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.edges.equalTo(self.view);
    //    }];
    //
    //    [self.view addSubview:self.pageLeftShadow];
    //    [self.pageLeftShadow mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.top.bottom.right.equalTo(self.view);
    //        make.width.mas_equalTo(30);
    //    }];
    //
    //    [self.view addSubview:self.pageRightShadow];
    //    [self.pageRightShadow mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.left.top.bottom.equalTo(self.view);
    //        make.width.mas_equalTo(30);
    //    }];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setIsLeft:(self.index % 2 == 0)];
}


#pragma mark - Setters
- (void)setContentImage:(UIImage *)contentImage {
    _contentImage = contentImage;

    self.imageView.image = contentImage;
}

- (void)setIsLeft:(BOOL)isLeft {
    _isLeft = isLeft;

    if (isLeft){
        self.pageLeftShadow.hidden  = NO;
        self.pageRightShadow.hidden = YES;
    } else{
        self.pageLeftShadow.hidden  = YES;
        self.pageRightShadow.hidden = NO;
    }
}


#pragma mark - Getters
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode   = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
    }

    return _imageView;
}

- (UIImageView *)pageLeftShadow {
    if (!_pageLeftShadow) {
        _pageLeftShadow = [[UIImageView alloc] init];
        _pageLeftShadow.image = [UIImage imageNamedInSPhotoBook:@"page_shadow_left"];
    }

    return _pageLeftShadow;
}

- (UIImageView *)pageRightShadow {
    if (!_pageRightShadow) {
        _pageRightShadow = [[UIImageView alloc] init];
        _pageRightShadow.image = [UIImage imageNamedInSPhotoBook:@"page_shadow_right"];
    }

    return _pageRightShadow;
}


@end
