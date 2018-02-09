//
//  TQImageViewer.h
//  TQImageViewer_Example
//
//  Created by TQTeam on 2018/2/6.
//  Copyright © 2018年 TQTeam. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, TQImageViewerLoadingStyle) {
    TQImageViewerLoadingStyleSpin = 0,
    TQImageViewerLoadingStyleProgress,
    TQImageViewerLoadingStyleIndicator
};

typedef NS_ENUM(NSUInteger, TQImageViewerPageLabelStyle) {
    TQImageViewerPageLabelStyleDot = 0,
    TQImageViewerPageLabelStyleNumber,
    TQImageViewerPageLabelStylePersonalityNumber,
    TQImageViewerPageLabelStyleNone
};

@interface TQImageViewerAttribute : NSObject

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIView *pressView;
@property (nonatomic, strong) UIImage *placeholderImage;

@end

@protocol TQImageViewerDelegate;
@interface TQImageViewer : UIView

@property (nonatomic, weak) id<TQImageViewerDelegate> delegate;
@property (nonatomic, assign) TQImageViewerLoadingStyle loadingStyle; // default is TQImageViewerLoadingStyleSpin
@property (nonatomic, assign) TQImageViewerPageLabelStyle pageLabelStyle; // default is TQImageViewerPageLabelStyleDot
@property (nonatomic, assign) BOOL alwaysShowPageLabel; // default is NO
@property (nonatomic, assign) BOOL bouncesAnimated; // default is NO

- (instancetype)initWithPhotos:(NSArray<TQImageViewerAttribute *> *)photos;

- (void)presentInView:(UIView *)view currentIndex:(NSInteger)currentIndex completion:(void (^)(void))completion;
- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion;

@end

@protocol TQImageViewerDelegate <NSObject>
@optional

- (void)imageViewer:(TQImageViewer *)imageViewer didLongPress:(UILongPressGestureRecognizer *)longPress attribute:(TQImageViewerAttribute *)attribute image:(UIImage *)image;

@end
