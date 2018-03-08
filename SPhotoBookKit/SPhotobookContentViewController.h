//
//  Copyright © 2018 ZhiweiSun. All rights reserved.
//
//  File name: SPhotobookContentViewController.h
//  Author:    ZhiweiSun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2018/3/6: Created by Cyrex on 2018/3/6
//

#import <UIKit/UIKit.h>

@interface SPhotobookContentViewController : UIViewController

@property (nonatomic, assign, readonly) NSInteger index;

@property (nonatomic, strong) UIImage *contentImage;

@property (nonatomic, strong) UIImageView *pageLeftShadow;
@property (nonatomic, strong) UIImageView *pageRightShadow;

- (instancetype)initWithIndex:(NSInteger)index;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end
