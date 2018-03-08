//
//  Copyright © 2018 ZhiweiSun. All rights reserved.
//
//  File name: SPhotoBookKit.h
//  Author:    ZhiweiSun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      03/06/2018: Created by Cyrex on 03/06/2018
//

#import <UIKit/UIKit.h>

//! Project version number for SPhotoBookKit.
FOUNDATION_EXPORT double SPhotoBookKitVersionNumber;

//! Project version string for SPhotoBookKit.
FOUNDATION_EXPORT const unsigned char SPhotoBookKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SPhotoBookKit/PublicHeader.h>
#if __has_include(<SPhotoBookKit/SPhotoBookKit.h>)
    #import <SPhotoBookKit/SPhotoBookViewController.h>
    #import <SPhotoBookKit/SPhotobookContentViewController.h>
#else
    #import "SPhotoBookViewController.h"
    #import "SPhotobookContentViewController.h"
#endif
