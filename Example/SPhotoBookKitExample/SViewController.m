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
//      03/06/2018: Created by Cyrex on 03/06/2018
//

#import "SViewController.h"

#import "SPhotoBookKit.h"
//#import "DFAScreenRecorder.h"

@interface SViewController () <SPhotoBookDataSource, SPhotoBookDelegate>

@property (nonatomic, strong) SPhotoBookViewController *bookViewController;

@property (nonatomic, strong) UIButton *nextButton;

@end

@implementation SViewController
#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self addChildViewController:self.bookViewController];
    [self.view addSubview:self.bookViewController.view];
    [self.bookViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.mas_equalTo(270);
        make.height.mas_equalTo(202);
    }];

    [self.bookViewController willMoveToParentViewController:self];
    [self.bookViewController didMoveToParentViewController:self];

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
    NSLog(@"%@", @(index));
    NSInteger nextIndex = index + 2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.bookViewController scrollBookViewControllerToIndex:index];

        if (nextIndex < [self.bookViewController.dataSource numberOfPhotoInBookViewController:self.bookViewController] - 1) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self scrollToNextPage:nextIndex];
            });
        }
    });
}


#pragma makr - Action Methods
- (void)didClickNextButton {
//    NSTimeInterval duration = [self.bookViewController.dataSource presentationCountForBookViewController:self.bookViewController] / 2;
//    [[DFAScreenRecorder sharedInstance] startRecordingWithView:self.bookViewController.view
//                                                          size:self.bookViewController.view.bounds.size
//                                                     timeScale:1];


    [self scrollToNextPage:0];

//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[DFAScreenRecorder sharedInstance] stopRecordingWithCompletion:^(NSURL * _Nullable url) {
//            NSLog(@"Recording Finished: %@", url);
//            if (!url) {
//                return;
//            }
//
//            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.relativePath)) {
//                UISaveVideoAtPathToSavedPhotosAlbum(url.relativePath,
//                                                    self,
//                                                    @selector(video:didFinishSavingWithError:contextInfo:),
//                                                    nil);
//            }
//        }];
//    });
}


 - (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
     NSLog(@"Job Done!");
 }


#pragma mark - SPhotoBookDataSource
- (NSInteger)numberOfPhotoInBookViewController:(SPhotoBookViewController *)bookViewController {
    return 6;
}

- (SPhotobookContentViewController *)bookViewController:(SPhotoBookViewController *)bookViewController
                          contentViewControllerForIndex:(NSInteger)index {

    SPhotobookContentViewController *vc = [[SPhotobookContentViewController alloc] initWithIndex:index];
    // NSString *tempalte = @"https://storage.googleapis.com/makefriends-8fd6d.appspot.com/photobook/cover/image_book_cover_%@.png";
//    [vc.imageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:tempalte, @(index + 1)]]];

    return vc;
}

- (UIImage *)userSubCoverImageForBookViewController:(SPhotoBookViewController *)bookViewController {
    CGSize size = CGSizeMake(10, 10);
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
    CGContextFillRect(context, (CGRect){.size = size});

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

#pragma mark - SPhotoBookDelegate
- (BOOL)shouldCloseBackCoverForBookViewController:(SPhotoBookViewController *)bookViewController {
    return NO;
}


#pragma makr - Getters
- (SPhotoBookViewController *)bookViewController {
    if (!_bookViewController) {
        _bookViewController = [[SPhotoBookViewController alloc] init];
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
