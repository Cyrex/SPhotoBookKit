//
//  Copyright © 2018 ZhiweiSun. All rights reserved.
//
//  File name: SPBookCoverView.m
//  Author:    ZhiweiSun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2018/9/19: Created by Cyrex on 2018/9/19
//

#import "SPBookCoverView.h"

@interface SPBookCoverView ()

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, strong, readwrite) UIImageView *coverImageView;

@end

@implementation SPBookCoverView
#pragma mark - Public Methods
- (void)udpateCoverImage:(UIImage *)coverImage {
    self.coverImageView.image = coverImage;
}


#pragma mark - Override
- (void)layoutSubviews {
    [super layoutSubviews];

    [self addGestureRecognizer:self.tapGesture];

    //    [self addSubview:self.coverImageView];
    //    [self.coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.edges.equalTo(self);
    //    }];
}


#pragma mark - Action Methods
- (void)didTap {
    [self.delegate didTapPhotoBookCover];
}


#pragma mark - Getters
- (UITapGestureRecognizer *)tapGesture {
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(didTap)];
    }

    return _tapGesture;
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.clipsToBounds = YES;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    }

    return _coverImageView;
}

@end

