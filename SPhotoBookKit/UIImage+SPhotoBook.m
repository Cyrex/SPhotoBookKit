//
//  Copyright © 2018 ZhiweiSun. All rights reserved.
//
//  File name: UIImage+SPhotoBook.m
//  Author:    ZhiweiSun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2018/3/8: Created by Cyrex on 2018/3/8
//

#import "UIImage+SPhotoBook.h"
#import "SPhotoBookViewController.h"

@implementation UIImage (SPhotoBook)
+ (UIImage *)imageNamedInSPhotoBook:(NSString *)name {
    UIImage *image;

    NSBundle *bundle = [NSBundle bundleForClass:[SPhotoBookViewController class]];
    image = [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];

    if (!image) {
        image = [UIImage imageNamed:name];
    }

    return image;
}

@end
