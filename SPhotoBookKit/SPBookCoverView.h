//
//  Copyright © 2018 ZhiweiSun. All rights reserved.
//
//  File name: SPBookCoverView.h
//  Author:    ZhiweiSun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2018/9/19: Created by Cyrex on 2018/9/19
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SPhotoBookCoverDelegate <NSObject>
@required
- (void)didTapPhotoBookCover;

@end

@interface SPBookCoverView : UIView

@property (nonatomic, strong, readonly) UIImageView *coverImageView;

@property (nonatomic, weak) id<SPhotoBookCoverDelegate> delegate;

- (void)udpateCoverImage:(UIImage *)coverImage;

@end

NS_ASSUME_NONNULL_END
