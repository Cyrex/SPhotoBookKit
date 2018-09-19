//
//  Copyright © 2018 ZhiweiSun. All rights reserved.
//
//  File name: SPBookViewController.h
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

@protocol SPBookDataSource;
@protocol SPBookDelegate;

@class SPBookContentViewController;

#pragma mark -
#pragma mark - SPBookViewController
@interface SPBookViewController : UIViewController

@property (nonatomic, weak) id<SPBookDataSource> dataSource;
@property (nonatomic, weak) id<SPBookDelegate> delegate;

@property (nonatomic, assign) BOOL startOpen;
@property (nonatomic, assign, readonly) BOOL bookClosed;

@property (nonatomic, weak) UIImageView *coverImageView;

- (void)scrollBookViewControllerToIndex:(NSInteger)index;

- (void)closeBookPhotoManual;

@end


#pragma mark -
#pragma mark - SPBookDataSource
@protocol SPBookDataSource <NSObject>
@required
- (NSInteger)numberOfPhotoInBookViewController:(SPBookViewController *)bookViewController;

- (__kindof SPBookContentViewController *)bookViewController:(SPBookViewController *)bookViewController
                               contentViewControllerForIndex:(NSInteger)index;

- (void)bookViewController:(SPBookViewController *)bookViewController coverView:(UIView *)contentView;

@optional
- (nullable UIImage *)leftCoverImageForBookViewController:(SPBookViewController *)bookViewController;
- (nullable UIImage *)rightCoverImageForBookViewController:(SPBookViewController *)bookViewController;

- (nullable UIImage *)bottomCoverImageForBookViewController:(SPBookViewController *)bookViewController;

@end


#pragma mark -
#pragma mark - SPBookDelegate
@protocol SPBookDelegate <NSObject>
@required

@optional
- (BOOL)shouldCloseBackCoverForBookViewController:(SPBookViewController *)bookViewController;

@end

NS_ASSUME_NONNULL_END

