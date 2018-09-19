//
//  Copyright © 2018 ZhiweiSun. All rights reserved.
//
//  File name: SPBookContentViewController.h
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

@interface SPBookContentViewController : UIViewController

@property (nonatomic, assign, readonly) NSInteger index;

@property (nonatomic, strong) UIImage *contentImage;

@property (nonatomic, strong) UIImageView *pageLeftShadow;
@property (nonatomic, strong) UIImageView *pageRightShadow;

- (instancetype)initWithIndex:(NSInteger)index;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
