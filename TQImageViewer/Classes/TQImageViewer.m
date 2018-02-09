//
//  TQImageViewer.m
//  TQImageViewer_Example
//
//  Created by TQTeam on 2018/2/6.
//  Copyright © 2018年 TQTeam. All rights reserved.
//

#import "TQImageViewer.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block) \
if ([NSThread isMainThread]) { \
block(); \
} else { \
dispatch_async(dispatch_get_main_queue(), block); \
}
#endif

@interface TQImageViewerAttribute ()
@property (nonatomic, assign) BOOL loadFinished;
@property (nonatomic, assign) BOOL placeholderInvalidate;
@end

@implementation TQImageViewerAttribute

- (void)setPressView:(UIView *)pressView {
    _pressView = pressView;
    _placeholderInvalidate = _pressView ? NO : YES;
}

- (UIImage *)placeholderImage {
    if (!_placeholderImage) {
        if ([_pressView respondsToSelector:@selector(image)]) {
            return ((UIImageView *)_pressView).image;
        }
    }
    return _placeholderImage;
}

@end


@interface TQImageViewerLayer : CAShapeLayer
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation TQImageViewerLayer

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        self.frame = frame;
        self.cornerRadius = 20;
        self.fillColor = [UIColor clearColor].CGColor;
        self.strokeColor = [UIColor whiteColor].CGColor;
        self.lineCap = kCALineCapRound;
        self.lineWidth = 4;
        self.strokeStart = 0;
        self.strokeEnd = 0.35;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
        self.hidden = YES;
        self.isLoading = NO;
        
        CGFloat inset = 2.f;
        self.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, inset, inset) cornerRadius:self.cornerRadius - inset].CGPath;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.isLoading) [self startSpinning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)startSpinning {
    self.hidden = NO;
    self.isLoading = YES;
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    anim.duration = 0.4;
    anim.toValue = @(M_PI - 0.5);
    anim.cumulative = YES;
    anim.repeatCount = MAXFLOAT;
    [self addAnimation:anim forKey:@"TQImageViewerLayerSpinKey"];
}

- (void)stopSpinning {
    self.hidden = YES;
    self.isLoading = NO;
    [self removeAnimationForKey:@"TQImageViewerLayerSpinKey"];
}

@end


@interface TQImageViewerCell : UIScrollView <UIScrollViewDelegate>
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) TQImageViewerLayer *loadingLayer;
@property (nonatomic, strong, readonly) UIActivityIndicatorView *indicator;
@property (nonatomic, assign) TQImageViewerLoadingStyle loadingStyle;
@property (nonatomic, strong) TQImageViewerAttribute *attribute;
@property (nonatomic, assign) NSInteger page;
@end

@implementation TQImageViewerCell

- (instancetype)init {
    if (self = [super init]) {
        self.bouncesZoom = YES;
        self.maximumZoomScale = 3;
        self.multipleTouchEnabled = YES;
        self.delegate = self;
        self.alwaysBounceVertical = NO;
        self.showsVerticalScrollIndicator = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.frame = [UIScreen mainScreen].bounds;
        
        // TODO
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        _imageView = [[UIImageView alloc] init];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.backgroundColor = [UIColor blackColor];
        [self addSubview:_imageView];
        
        _loadingLayer = [[TQImageViewerLayer alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        [self.layer addSublayer:_loadingLayer];
        
        _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _indicator.color = [UIColor whiteColor];
        [self addSubview:_indicator];
        [self subviewsFrameAdjust];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = _loadingLayer.frame;
    CGPoint point = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    frame.origin.x = point.x - frame.size.width / 2;
    frame.origin.y = point.y - frame.size.height / 2;
    _loadingLayer.frame = frame;
    _indicator.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

- (void)subviewsFrameAdjust {
    _imageView.frame = CGRectMake(0, 0, self.bounds.size.width, 0);
    CGRect imageRect = _imageView.frame;
    UIImage *image = _imageView.image;
    if (image.size.height / image.size.width > self.bounds.size.height / self.bounds.size.width) {
        imageRect.size.height = floor(image.size.height / (image.size.width / self.bounds.size.width));
        _imageView.frame = imageRect;
    } else {
        CGFloat height = image.size.height / image.size.width * self.bounds.size.width;
        if (height < 1 || isnan(height)) height = self.bounds.size.height;
        height = floor(height);
        imageRect.size.height = height;
        _imageView.frame = imageRect;
        _imageView.center = CGPointMake(_imageView.center.x, self.bounds.size.height / 2);
    }
    if (_imageView.frame.size.height > self.bounds.size.height && _imageView.frame.size.height - self.bounds.size.height <= 1) {
        imageRect.size.height = self.bounds.size.height;
        _imageView.frame = imageRect;
    }
    self.contentSize = CGSizeMake(self.bounds.size.width, MAX(_imageView.frame.size.height, self.bounds.size.height));
    [self scrollRectToVisible:self.bounds animated:NO];
    if (_imageView.frame.size.height <= self.bounds.size.height) {
        self.alwaysBounceVertical = NO;
    } else {
        self.alwaysBounceVertical = YES;
    }
}

- (void)cancelCurrentLoad {
    [_imageView sd_cancelCurrentImageLoad];
    [_loadingLayer stopSpinning];
    [_indicator stopAnimating];
}

- (void)setLoadingStyle:(TQImageViewerLoadingStyle)loadingStyle {
    _loadingStyle = loadingStyle;
}

- (void)setAttribute:(TQImageViewerAttribute *)attribute {
    if (_attribute == attribute) return;
    _attribute = attribute;
    
    _attribute.loadFinished = NO;
    [self cancelCurrentLoad];
    
    [self setZoomScale:1.0 animated:NO];
    self.maximumZoomScale = 1;
    
    if (!_attribute) {
        _imageView.image = nil;
        return;
    }
    
    if (attribute.image) {
        _attribute.loadFinished = YES;
        _imageView.image = attribute.image;
        [self subviewsFrameAdjust];
    } else if (attribute.imageURL) {
        __weak typeof(self) weakSelf = self;
        SDWebImageDownloaderProgressBlock progressCallback = nil;
        if (_loadingStyle == TQImageViewerLoadingStyleProgress) {
            progressCallback = ^(NSInteger receivedSize, NSInteger expectedSize, NSURL *targetURL) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                dispatch_main_async_safe(^{
                    CGFloat progress = receivedSize / (float)expectedSize;
                    progress = progress < 0.01 ? 0.01 : progress > 1 ? 1 : progress;
                    if (isnan(progress)) progress = 0;
                    strongSelf.loadingLayer.hidden = NO;
                    strongSelf.loadingLayer.strokeEnd = progress;
                });
            };
        } else if (_loadingStyle == TQImageViewerLoadingStyleSpin) {
            [_loadingLayer startSpinning];
        } else { // TQImageViewerLoadingStyleIndicator
            [_indicator startAnimating];
            if (_attribute.placeholderInvalidate) {
                attribute.placeholderImage = nil;
            }
        }
        [_imageView sd_setImageWithURL:attribute.imageURL placeholderImage:attribute.placeholderImage options:kNilOptions progress:progressCallback completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return ;
            if (_loadingStyle == TQImageViewerLoadingStyleSpin) {
                [strongSelf.loadingLayer stopSpinning];
            } else if (strongSelf.loadingStyle == TQImageViewerLoadingStyleProgress) {
                strongSelf.loadingLayer.hidden = YES;
            } else { // TQImageViewerLoadingStyleIndicator
                [strongSelf.indicator stopAnimating];
                if (strongSelf.attribute.placeholderInvalidate) {
                    _imageView.alpha = 0;
                    [UIView animateWithDuration:0.2 animations:^{
                        _imageView.alpha = 1;
                    }];
                }
            }
            if (image) {
                strongSelf.attribute.loadFinished = YES;
                [self subviewsFrameAdjust];
                self.maximumZoomScale = 3;
            }
        }];
        [self subviewsFrameAdjust];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    UIView *subView = _imageView;
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

@end


@interface TQImageViewer () <UIGestureRecognizerDelegate, UIScrollViewDelegate>
@property (nonatomic, strong, readonly) UIView *containerView;
@property (nonatomic, strong, readonly) UIScrollView  *scrollView;
@property (nonatomic, strong, readonly) UIPageControl *pageControl;
@property (nonatomic, strong, readonly) UILabel *pageTextLabel;
@property (nonatomic, weak, readonly) UIView *fromView;
@property (nonatomic, assign, readonly) CGFloat pageSpacing;
@property (nonatomic, assign, readonly) NSTimeInterval animateDuration;
@property (nonatomic, assign, readonly) BOOL isPresenting;
@property (nonatomic, assign, readonly) BOOL fromStatusBarHidden;
@property (nonatomic, strong, readonly) NSArray<TQImageViewerAttribute *> *photos;
@property (nonatomic, strong, readonly) NSMutableArray<TQImageViewerCell *> *reusableCells;
@end

@implementation TQImageViewer

- (instancetype)initWithPhotos:(NSArray<TQImageViewerAttribute *> *)photos {
    NSParameterAssert(photos.count);
    if (self = [super init]) {
        self.frame = [UIScreen mainScreen].bounds;
        self.clipsToBounds = YES;
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        singleTap.delegate = self;
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTap.delegate = self;
        doubleTap.numberOfTapsRequired = 2;
        [singleTap requireGestureRecognizerToFail:doubleTap];
        [self addGestureRecognizer:doubleTap];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        longPress.delegate = self;
        [self addGestureRecognizer:longPress];
        
        _photos = [photos copy];
        _reusableCells = [NSMutableArray array];
        _pageSpacing = 20;
        _animateDuration = 0.2;
        _loadingStyle = TQImageViewerLoadingStyleSpin;
        _pageLabelStyle = TQImageViewerPageLabelStyleDot;
        _alwaysShowPageLabel = NO;
        _bouncesAnimated = NO;
        
        [self subviewsInitialization];
    }
    return self;
}

- (void)subviewsInitialization {
    _containerView = [[UIView alloc] init];
    _containerView.frame = self.bounds;
    _containerView.backgroundColor = [UIColor blackColor];
    _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_containerView];
    
    _scrollView = [UIScrollView new];
    _scrollView.frame = CGRectMake(-_pageSpacing / 2, 0, self.frame.size.width + _pageSpacing, self.frame.size.height);
    _scrollView.delegate = self;
    _scrollView.scrollsToTop = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.delaysContentTouches = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.canCancelContentTouches = YES;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.alwaysBounceHorizontal = _photos.count > 1;
    [self addSubview:_scrollView];
    
    _pageControl = [[UIPageControl alloc] init];
    _pageControl.hidesForSinglePage = YES;
    _pageControl.userInteractionEnabled = NO;
    _pageControl.frame = CGRectMake(0, 0, self.frame.size.width - 40, 10);
    _pageControl.pageIndicatorTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    _pageControl.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height - 20);
    _pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _pageControl.alpha = 0;
    [self addSubview:_pageControl];
    
    _pageTextLabel = [[UILabel alloc] init];
    _pageTextLabel.frame = CGRectMake(0, 0, 120, 30);
    _pageTextLabel.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height - 40);
    _pageTextLabel.textColor = [UIColor whiteColor];
    _pageTextLabel.textAlignment = NSTextAlignmentCenter;
    _pageTextLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    _pageTextLabel.alpha = 0;
    [self addSubview:_pageTextLabel];
}

#pragma mark - Present

- (void)presentInView:(UIView *)view currentIndex:(NSInteger)currentIndex completion:(void (^)(void))completion {
    _fromStatusBarHidden = [UIApplication sharedApplication].isStatusBarHidden;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // If you use application object to manage the status bar, You need to be in `Info.plist` file `View controller-based status bar appearance` corresponding value set to NO, otherwise the application object set is invalid.
    [UIApplication.sharedApplication setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
    
    if (!view) {
        view = [UIApplication sharedApplication].keyWindow ?: [[UIApplication sharedApplication].delegate window];
    }
    [view addSubview:self];
    
    NSInteger page = currentIndex;
    if (page <= 0) page = 0;
    [self setupPageLabelWithPage:page];
    
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * _photos.count, _scrollView.frame.size.height);
    [_scrollView scrollRectToVisible:CGRectMake(_scrollView.frame.size.width * page, 0, _scrollView.frame.size.width, _scrollView.frame.size.height) animated:NO];
    [self scrollViewDidScroll:_scrollView];
    
    NSInteger currentPage = [self currentPage];
    TQImageViewerCell *cell = [self cellForPage:currentPage];
    TQImageViewerAttribute *attribute = [_photos objectAtIndex:currentPage];
    
    _fromView = attribute.pressView;
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    NSString *cacheKey = [manager cacheKeyForURL:attribute.imageURL];
    if ([manager.imageCache imageFromMemoryCacheForKey:cacheKey]) {
        cell.attribute = attribute;
    } else {
        cell.imageView.image = attribute.placeholderImage;
        [cell subviewsFrameAdjust];
    }
    
    void (^completionCallback)(void) = ^() {
        _isPresenting = YES;
        cell.loadingStyle = self.loadingStyle;
        cell.attribute = attribute;
        [self hidePageLabel];
    };
    if (_fromView) {
        CGRect fromFrame = [_fromView convertRect:_fromView.frame toView:cell];
        CGRect toFrame = cell.imageView.frame;
        cell.imageView.frame = fromFrame;
        _containerView.backgroundColor = [UIColor clearColor];
        if (self.bouncesAnimated) {
            [UIView animateWithDuration:0.15 animations:^{
                _containerView.backgroundColor = [UIColor blackColor];
            }];
            [UIView animateWithDuration:0.55 delay:0.f usingSpringWithDamping:0.6 initialSpringVelocity:0.2 options:UIViewAnimationOptionCurveLinear animations:^{
                cell.imageView.frame = toFrame;
            } completion:^(BOOL finished) {
                if (!finished) return ;
                if (completionCallback) completionCallback();
                if (completion) completion();
            }];
        } else {
            [UIView animateWithDuration:_animateDuration animations:^{
                _containerView.backgroundColor = [UIColor blackColor];
                cell.imageView.frame = toFrame;
            } completion:^(BOOL finished) {
                if (!finished) return ;
                if (completionCallback) completionCallback();
                if (completion) completion();
            }];
        }
    } else { // fade
        self.alpha = 0;
        _containerView.alpha = 0;
        cell.imageView.alpha = 0;
        [UIView animateWithDuration:_animateDuration animations:^{
            _containerView.alpha = 1;
            cell.imageView.alpha = 1;
            self.alpha = 1;
        } completion:^(BOOL finished) {
            if (!finished) return ;
            if (completionCallback) completionCallback();
            if (completion) completion();
        }];
    }
}

#pragma mark - Dismiss

- (void)dismiss {
    [self dismissAnimated:YES completion:NULL];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [UIApplication.sharedApplication setStatusBarHidden:_fromStatusBarHidden withAnimation:UIStatusBarAnimationNone];
#pragma clang diagnostic pop
    
    if (!animated) _animateDuration = 0;
    NSInteger currentPage = [self currentPage];
    TQImageViewerCell *cell = [self cellForPage:currentPage];
    TQImageViewerAttribute *attribute = [_photos objectAtIndex:currentPage];
    UIView *fromView = attribute.pressView;
    
    [self cancelAllImageLoad];
    
    [UIView animateWithDuration:0.15 animations:^{
        _pageTextLabel.alpha = _pageControl.alpha = 0;
    }];
    
    void (^dismissCallback)(void) = ^() {
        _isPresenting = NO;
        [self removeFromSuperview];
    };
    if (fromView) {
        CGRect fromFrame = [fromView convertRect:fromView.bounds toView:cell];
        if (self.bouncesAnimated) {
            [UIView animateWithDuration:0.15 animations:^{
                _containerView.alpha = 0;
                self.backgroundColor = [UIColor clearColor];
            }];
            [UIView animateWithDuration:0.55 delay:0.f usingSpringWithDamping:0.6 initialSpringVelocity:0.2 options:UIViewAnimationOptionCurveLinear animations:^{
                cell.imageView.frame = fromFrame;
            } completion:^(BOOL finished) {
                if (!finished) return ;
                if (dismissCallback) dismissCallback();
                if (completion) completion();
            }];
        } else {
            [UIView animateWithDuration:_animateDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                cell.imageView.frame = fromFrame;
                _containerView.alpha = 0;
                self.backgroundColor = [UIColor clearColor];
            } completion:^(BOOL finished) {
                if (!finished) return ;
                if (dismissCallback) dismissCallback();
                if (completion) completion();
            }];
        }
    } else { // fade
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            if (!finished) return ;
            if (dismissCallback) dismissCallback();
            if (completion) completion();
        }];
    }
}

#pragma mark - CancelImageLoad

- (void)cancelAllImageLoad {
    [_reusableCells enumerateObjectsUsingBlock:^(TQImageViewerCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        [cell cancelCurrentLoad];
    }];
}

#pragma mark - Page label

- (void)setupPageLabelWithPage:(NSInteger)page {
    switch (self.pageLabelStyle) {
        case TQImageViewerPageLabelStyleDot: {
            [_pageTextLabel removeFromSuperview];
            _pageControl.numberOfPages = _photos.count;
            _pageControl.currentPage = page;
        } break;
        case TQImageViewerPageLabelStyleNumber: {
            [_pageControl removeFromSuperview];
            _pageTextLabel.attributedText = [self attributedText:page+1 total:_photos.count];
        } break;
        case TQImageViewerPageLabelStylePersonalityNumber: {
            [_pageControl removeFromSuperview];
            _pageTextLabel.attributedText = [self attributedText:page+1 total:_photos.count];
        } break;
        default: { // TQImageViewerPageLabelStyleNone
            [_pageTextLabel removeFromSuperview];
            [_pageControl removeFromSuperview];
        } break;
    }
}

- (NSMutableAttributedString *)attributedText:(NSInteger)current total:(NSInteger)total {
    NSString *currentText = [NSString stringWithFormat:@"%ld", (long)current];
    NSString *totalText = [NSString stringWithFormat:@" / %ld", (long)total];
    NSString *text = [currentText stringByAppendingString:totalText];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    if (self.pageLabelStyle == TQImageViewerPageLabelStylePersonalityNumber) {
        [attributedText addAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"Georgia" size:17],
                                        NSForegroundColorAttributeName : [UIColor whiteColor]} range:[text rangeOfString:totalText]];
        [attributedText addAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"Georgia-Bold" size:27],
                                        NSForegroundColorAttributeName : [UIColor whiteColor]} range:[text rangeOfString:currentText]];
    }
    return attributedText;
}

- (void)hidePageLabel {
    if (self.alwaysShowPageLabel) return;
    [UIView animateWithDuration:0.45 delay:0.65 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:^{
        _pageTextLabel.alpha = _pageControl.alpha = 0;
    } completion:NULL];
}

- (NSInteger)currentPage {
    NSInteger page = _scrollView.contentOffset.x / _scrollView.frame.size.width + 0.5;
    if (page >= _photos.count) page = (NSInteger)_photos.count - 1;
    if (page < 0) page = 0;
    return page;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) [self hidePageLabel];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self hidePageLabel];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateReusableCells];
    CGFloat floatPage = _scrollView.contentOffset.x / _scrollView.frame.size.width;
    NSInteger page = _scrollView.contentOffset.x / _scrollView.frame.size.width + 0.5;
    for (NSInteger i = page - 1; i <= page + 1; i++) {
        if (i >= 0 && i < _photos.count) {
            TQImageViewerCell *cell = [self cellForPage:i];
            if (!cell) {
                TQImageViewerCell *cell = [self dequeueReusableCell];
                cell.page = i;
                CGRect cellRect = cell.frame;
                cellRect.origin.x = (self.frame.size.width + _pageSpacing) * i + _pageSpacing / 2;
                cell.frame = cellRect;
                if (_isPresenting) {
                    cell.loadingStyle = self.loadingStyle;
                    cell.attribute = _photos[i];
                }
                [_scrollView addSubview:cell];
            } else {
                if (_isPresenting && !cell.attribute) {
                    cell.loadingStyle = self.loadingStyle;
                    cell.attribute = _photos[i];
                }
            }
        }
    }
    NSInteger intPage = floatPage + 0.5;
    intPage = intPage < 0 ? 0 : intPage >= _photos.count ? (int)_photos.count - 1 : intPage;
    _pageControl.currentPage = intPage;
    _pageTextLabel.attributedText = [self attributedText:page+1 total:_photos.count];
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        _pageControl.alpha = 1;
        _pageTextLabel.alpha = 1;
    }completion:NULL];
}

#pragma mark - Reusable Cells

- (void)updateReusableCells {
    for (TQImageViewerCell *cell in _reusableCells) {
        if (cell.superview) {
            if (cell.frame.origin.x > _scrollView.contentOffset.x + _scrollView.frame.size.width * 2 ||
                (cell.frame.origin.x + cell.frame.size.width) < _scrollView.contentOffset.x - _scrollView.frame.size.width) {
                [cell removeFromSuperview];
                cell.page = -1;
                cell.attribute = nil;
            }
        }
    }
}

- (TQImageViewerCell *)cellForPage:(NSInteger)page {
    for (TQImageViewerCell *cell in _reusableCells) {
        if (cell.page == page) return cell;
    }
    return nil;
}

- (TQImageViewerCell *)dequeueReusableCell {
    TQImageViewerCell *cell = nil;
    for (cell in _reusableCells) {
        if (!cell.superview) return cell;
    }
    cell = [[TQImageViewerCell alloc] init];
    cell.frame = self.bounds;
    cell.page = -1;
    cell.attribute = nil;
    [_reusableCells addObject:cell];
    return cell;
}

#pragma mark - Events

- (void)doubleTap:(UITapGestureRecognizer *)g {
    if (!_isPresenting) return;
    TQImageViewerCell *tile = [self cellForPage:self.currentPage];
    if (tile) {
        if (tile.zoomScale > 1) {
            [tile setZoomScale:1 animated:YES];
        } else {
            CGPoint touchPoint = [g locationInView:tile.imageView];
            CGFloat newZoomScale = tile.maximumZoomScale;
            CGFloat xsize = self.frame.size.width / newZoomScale;
            CGFloat ysize = self.frame.size.height / newZoomScale;
            [tile zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
        }
    }
}

- (void)longPress:(UILongPressGestureRecognizer *)g {
    if (!_isPresenting) return;
    if (g.state != UIGestureRecognizerStateBegan) return;
    NSInteger currentPage = [self currentPage];
    TQImageViewerCell *cell = [self cellForPage:currentPage];
    TQImageViewerAttribute *attribute = [_photos objectAtIndex:currentPage];
    if ([self.delegate respondsToSelector:@selector(imageViewer:didLongPress:attribute:image:)]) {
        [self.delegate imageViewer:self didLongPress:g attribute:attribute image:cell.imageView.image];
    }
}

@end
