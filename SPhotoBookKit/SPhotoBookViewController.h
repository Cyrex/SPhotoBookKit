//
//  Copyright © 2018 ZhiweiSun. All rights reserved.
//
//  File name: SPhotoBookViewController.h
//  Author:    ZhiweiSun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2018/3/6: Created by Cyrex on 2018/3/6
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SPhotoBookDataSource;
@protocol SPhotoBookDelegate;

@class SPhotobookContentViewController;

#pragma mark -
#pragma mark - SPhotoBookViewController
@interface SPhotoBookViewController : UIViewController

@property (nonatomic, weak) id<SPhotoBookDataSource> dataSource;
@property (nonatomic, weak) id<SPhotoBookDelegate> delegate;

@property (nonatomic, assign) BOOL startOpen;
@property (nonatomic, assign, readonly) BOOL bookClosed;

@property (nonatomic, weak) UIImageView *coverImageView;

- (void)scrollBookViewControllerToIndex:(NSInteger)index;

@end


#pragma mark -
#pragma mark - SPhotoBookDataSource
@protocol SPhotoBookDataSource <NSObject>
@required
- (NSInteger)numberOfPhotoInBookViewController:(SPhotoBookViewController *)bookViewController;

- (__kindof SPhotobookContentViewController *)bookViewController:(SPhotoBookViewController *)bookViewController
                                   contentViewControllerForIndex:(NSInteger)index;

- (UIImage *)userSubCoverImageForBookViewController:(SPhotoBookViewController *)bookViewController;

@optional
- (nullable UIImage *)leftCoverImageForBookViewController:(SPhotoBookViewController *)bookViewController;
- (nullable UIImage *)rightCoverImageForBookViewController:(SPhotoBookViewController *)bookViewController;

- (nullable UIImage *)bottomCoverImageForBookViewController:(SPhotoBookViewController *)bookViewController;

@end


#pragma mark -
#pragma mark - SPhotoBookDelegate
@protocol SPhotoBookDelegate <NSObject>
@required

@optional
- (BOOL)shouldCloseBackCoverForBookViewController:(SPhotoBookViewController *)bookViewController;

@end

NS_ASSUME_NONNULL_END
